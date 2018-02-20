//===- SymbolTable.cpp ----------------------------------------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "SymbolTable.h"

#include "Config.h"
#include "InputChunks.h"
#include "WriterUtils.h"
#include "lld/Common/ErrorHandler.h"
#include "lld/Common/Memory.h"
#include "llvm/ADT/SetVector.h"

#define DEBUG_TYPE "lld"

using namespace llvm;
using namespace llvm::wasm;
using namespace lld;
using namespace lld::wasm;

SymbolTable *lld::wasm::Symtab;

void SymbolTable::addFile(InputFile *File) {
  log("Processing: " + toString(File));
  File->parse();

  if (auto *F = dyn_cast<ObjFile>(File))
    ObjectFiles.push_back(F);
}

void SymbolTable::reportRemainingUndefines() {
  SetVector<Symbol *> Undefs;
  for (Symbol *Sym : SymVector) {
    if (Sym->isUndefined() && !Sym->isWeak() &&
        Config->AllowUndefinedSymbols.count(Sym->getName()) == 0) {
      Undefs.insert(Sym);
    }
  }

  if (Undefs.empty())
    return;

  for (ObjFile *File : ObjectFiles)
    for (Symbol *Sym : File->getSymbols())
      if (Undefs.count(Sym))
        error(toString(File) + ": undefined symbol: " + toString(*Sym));

  for (Symbol *Sym : Undefs)
    if (!Sym->getFile())
      error("undefined symbol: " + toString(*Sym));
}

Symbol *SymbolTable::find(StringRef Name) {
  auto It = SymMap.find(CachedHashStringRef(Name));
  if (It == SymMap.end())
    return nullptr;
  return It->second;
}

std::pair<Symbol *, bool> SymbolTable::insert(StringRef Name) {
  Symbol *&Sym = SymMap[CachedHashStringRef(Name)];
  if (Sym)
    return {Sym, false};
  Sym = reinterpret_cast<Symbol *>(make<SymbolUnion>());
  SymVector.emplace_back(Sym);
  return {Sym, true};
}

// Check the type of new symbol matches that of the symbol is replacing.
// For functions this can also involve verifying that the signatures match.
static void checkSymbolTypes(const Symbol &Existing, const InputFile &F,
                             bool NewIsFunction, const WasmSignature *NewSig) {
  if (Existing.isLazy())
    return;

  // First check the symbol types match (i.e. either both are function
  // symbols or both are data symbols).
  if (isa<FunctionSymbol>(Existing) != NewIsFunction) {
    error("symbol type mismatch: " + Existing.getName() + "\n>>> defined as " +
          (isa<FunctionSymbol>(Existing) ? "Function" : "Global") + " in " +
          toString(Existing.getFile()) + "\n>>> defined as " +
          (NewIsFunction ? "Function" : "Global") + " in " + F.getName());
    return;
  }

  // For function symbols, optionally check the function signature matches too.
  auto *ExistingFunc = dyn_cast<FunctionSymbol>(&Existing);
  if (!ExistingFunc || !Config->CheckSignatures)
    return;

  const WasmSignature *OldSig = ExistingFunc->getFunctionType();

  // Skip the signature check if the existing function has no signature (e.g.
  // if it is an undefined symbol generated by --undefined command line flag).
  if (OldSig == nullptr)
    return;

  DEBUG(dbgs() << "checkSymbolTypes: " << ExistingFunc->getName() << "\n");
  assert(NewSig);

  if (*NewSig == *OldSig)
    return;

  error("function signature mismatch: " + ExistingFunc->getName() +
        "\n>>> defined as " + toString(*OldSig) + " in " +
        toString(ExistingFunc->getFile()) + "\n>>> defined as " +
        toString(*NewSig) + " in " + F.getName());
}

static void checkSymbolTypes(const Symbol &Existing, const InputFile &F,
                             bool IsFunction, const InputChunk *Chunk) {
  const WasmSignature *Sig = nullptr;
  if (auto *F = dyn_cast_or_null<InputFunction>(Chunk))
    Sig = &F->Signature;
  return checkSymbolTypes(Existing, F, IsFunction, Sig);
}

DefinedFunction *SymbolTable::addSyntheticFunction(StringRef Name,
                                                   const WasmSignature *Type,
                                                   uint32_t Flags) {
  DEBUG(dbgs() << "addSyntheticFunction: " << Name << "\n");
  Symbol *S;
  bool WasInserted;
  std::tie(S, WasInserted) = insert(Name);
  assert(WasInserted);
  return replaceSymbol<DefinedFunction>(S, Name, Flags, Type);
}

DefinedGlobal *SymbolTable::addSyntheticGlobal(StringRef Name, uint32_t Flags) {
  DEBUG(dbgs() << "addSyntheticGlobal: " << Name << "\n");
  Symbol *S;
  bool WasInserted;
  std::tie(S, WasInserted) = insert(Name);
  assert(WasInserted);
  return replaceSymbol<DefinedGlobal>(S, Name, Flags);
}

struct NewSymbol {
  InputFile *File;
  uint32_t Flags;
  InputChunk *Chunk;
  bool IsFunction;
};

static bool shouldReplace(const Symbol &Existing, const NewSymbol &New) {
  bool Replace = false;
  bool CheckTypes = false;

  if (Existing.isLazy()) {
    // Existing symbol is lazy. Replace it without checking types since
    // lazy symbols don't have any type information.
    DEBUG(dbgs() << "replacing existing lazy symbol: " << Existing.getName()
                 << "\n");
    Replace = true;
  } else if (!Existing.isDefined()) {
    // Existing symbol is undefined: replace it, while check types.
    DEBUG(dbgs() << "resolving existing undefined symbol: "
                 << Existing.getName() << "\n");
    Replace = true;
    CheckTypes = true;
  } else if ((New.Flags & WASM_SYMBOL_BINDING_MASK) == WASM_SYMBOL_BINDING_WEAK) {
    // the new symbol is weak we can ignore it
    DEBUG(dbgs() << "existing symbol takes precedence\n");
    CheckTypes = true;
  } else if (Existing.isWeak()) {
    // the existing symbol is, so we replace it
    DEBUG(dbgs() << "replacing existing weak symbol\n");
    Replace = true;
    CheckTypes = true;
  } else {
    // neither symbol is week. They conflict.
    error("duplicate symbol: " + toString(Existing) + "\n>>> defined in " +
          toString(Existing.getFile()) + "\n>>> defined in " +
          toString(New.File));
  }

  if (CheckTypes)
    checkSymbolTypes(Existing, *New.File, New.IsFunction, New.Chunk);

  return Replace;
}

Symbol *SymbolTable::addDefinedFunction(StringRef Name, uint32_t Flags,
                                        InputFile *F, InputFunction *Function) {
  DEBUG(dbgs() << "addDefinedFunction: " << Name << "\n");
  Symbol *S;
  bool WasInserted;
  std::tie(S, WasInserted) = insert(Name);
  NewSymbol New{F, Flags, Function, true};
  if (WasInserted || shouldReplace(*S, New))
    replaceSymbol<DefinedFunction>(S, Name, Flags, F, Function);
  return S;
}

Symbol *SymbolTable::addDefinedGlobal(StringRef Name, uint32_t Flags,
                                      InputFile *F, InputSegment *Segment,
                                      uint32_t Address) {
  DEBUG(dbgs() << "addDefinedGlobal:" << Name << " addr:" << Address << "\n");
  Symbol *S;
  bool WasInserted;
  std::tie(S, WasInserted) = insert(Name);
  NewSymbol New{F, Flags, Segment, false};
  if (WasInserted || shouldReplace(*S, New))
    replaceSymbol<DefinedGlobal>(S, Name, Flags, F, Segment, Address);
  return S;
}

Symbol *SymbolTable::addUndefined(StringRef Name, Symbol::Kind Kind,
                                  uint32_t Flags, InputFile *F,
                                  const WasmSignature *Type) {
  DEBUG(dbgs() << "addUndefined: " << Name << "\n");
  Symbol *S;
  bool WasInserted;
  std::tie(S, WasInserted) = insert(Name);
  bool IsFunction = Kind == Symbol::UndefinedFunctionKind;
  if (WasInserted) {
    if (IsFunction)
      replaceSymbol<UndefinedFunction>(S, Name, Flags, F, Type);
    else
      replaceSymbol<UndefinedGlobal>(S, Name, Flags, F);
  } else if (auto *LazySym = dyn_cast<LazySymbol>(S)) {
    DEBUG(dbgs() << "resolved by existing lazy\n");
    auto *AF = cast<ArchiveFile>(LazySym->getFile());
    AF->addMember(&LazySym->getArchiveSymbol());
  } else if (S->isDefined()) {
    DEBUG(dbgs() << "resolved by existing\n");
    checkSymbolTypes(*S, *F, IsFunction, Type);
  }
  return S;
}

void SymbolTable::addLazy(ArchiveFile *F, const Archive::Symbol *Sym) {
  DEBUG(dbgs() << "addLazy: " << Sym->getName() << "\n");
  StringRef Name = Sym->getName();
  Symbol *S;
  bool WasInserted;
  std::tie(S, WasInserted) = insert(Name);
  if (WasInserted) {
    replaceSymbol<LazySymbol>(S, Name, F, *Sym);
  } else if (S->isUndefined()) {
    // There is an existing undefined symbol.  The can load from the
    // archive.
    DEBUG(dbgs() << "replacing existing undefined\n");
    F->addMember(Sym);
  }
}

bool SymbolTable::addComdat(StringRef Name, ObjFile *F) {
  DEBUG(dbgs() << "addComdat: " << Name << "\n");
  ObjFile *&File = ComdatMap[CachedHashStringRef(Name)];
  if (File) {
    DEBUG(dbgs() << "COMDAT already defined\n");
    return false;
  }
  File = F;
  return true;
}

ObjFile *SymbolTable::findComdat(StringRef Name) const {
  auto It = ComdatMap.find(CachedHashStringRef(Name));
  return It == ComdatMap.end() ? nullptr : It->second;
}
