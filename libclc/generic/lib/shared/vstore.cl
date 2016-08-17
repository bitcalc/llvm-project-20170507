#include <clc/clc.h>

#pragma OPENCL EXTENSION cl_khr_byte_addressable_store : enable

#define VSTORE_VECTORIZE(PRIM_TYPE, ADDR_SPACE) \
  typedef PRIM_TYPE##2 less_aligned_##ADDR_SPACE##PRIM_TYPE##2 __attribute__ ((aligned (sizeof(PRIM_TYPE))));\
  _CLC_OVERLOAD _CLC_DEF void vstore2(PRIM_TYPE##2 vec, size_t offset, ADDR_SPACE PRIM_TYPE *mem) { \
    *((ADDR_SPACE less_aligned_##ADDR_SPACE##PRIM_TYPE##2*) (&mem[2*offset])) = vec; \
  } \
\
  _CLC_OVERLOAD _CLC_DEF void vstore3(PRIM_TYPE##3 vec, size_t offset, ADDR_SPACE PRIM_TYPE *mem) { \
    *((ADDR_SPACE less_aligned_##ADDR_SPACE##PRIM_TYPE##2*) (&mem[3*offset])) = (PRIM_TYPE##2)(vec.s0, vec.s1); \
    mem[3 * offset + 2] = vec.s2;\
  } \
\
  typedef PRIM_TYPE##4 less_aligned_##ADDR_SPACE##PRIM_TYPE##4 __attribute__ ((aligned (sizeof(PRIM_TYPE))));\
  _CLC_OVERLOAD _CLC_DEF void vstore4(PRIM_TYPE##4 vec, size_t offset, ADDR_SPACE PRIM_TYPE *mem) { \
    *((ADDR_SPACE less_aligned_##ADDR_SPACE##PRIM_TYPE##4*) (&mem[4*offset])) = vec; \
  } \
\
  typedef PRIM_TYPE##8 less_aligned_##ADDR_SPACE##PRIM_TYPE##8 __attribute__ ((aligned (sizeof(PRIM_TYPE))));\
  _CLC_OVERLOAD _CLC_DEF void vstore8(PRIM_TYPE##8 vec, size_t offset, ADDR_SPACE PRIM_TYPE *mem) { \
    *((ADDR_SPACE less_aligned_##ADDR_SPACE##PRIM_TYPE##8*) (&mem[8*offset])) = vec; \
  } \
\
  typedef PRIM_TYPE##16 less_aligned_##ADDR_SPACE##PRIM_TYPE##16 __attribute__ ((aligned (sizeof(PRIM_TYPE))));\
  _CLC_OVERLOAD _CLC_DEF void vstore16(PRIM_TYPE##16 vec, size_t offset, ADDR_SPACE PRIM_TYPE *mem) { \
    *((ADDR_SPACE less_aligned_##ADDR_SPACE##PRIM_TYPE##16*) (&mem[16*offset])) = vec; \
  } \

#define VSTORE_ADDR_SPACES(__CLC_SCALAR___CLC_GENTYPE) \
    VSTORE_VECTORIZE(__CLC_SCALAR___CLC_GENTYPE, __private) \
    VSTORE_VECTORIZE(__CLC_SCALAR___CLC_GENTYPE, __local) \
    VSTORE_VECTORIZE(__CLC_SCALAR___CLC_GENTYPE, __global) \

#define VSTORE_TYPES() \
    VSTORE_ADDR_SPACES(char) \
    VSTORE_ADDR_SPACES(uchar) \
    VSTORE_ADDR_SPACES(short) \
    VSTORE_ADDR_SPACES(ushort) \
    VSTORE_ADDR_SPACES(int) \
    VSTORE_ADDR_SPACES(uint) \
    VSTORE_ADDR_SPACES(long) \
    VSTORE_ADDR_SPACES(ulong) \
    VSTORE_ADDR_SPACES(float) \

VSTORE_TYPES()

#ifdef cl_khr_fp64
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
    VSTORE_ADDR_SPACES(double)
#endif

/* vstore_half are legal even without cl_khr_fp16 */

#define VEC_STORE1(val) mem[offset++] = val;
#define VEC_STORE2(val) \
	VEC_STORE1(val.lo) \
	VEC_STORE1(val.hi)
#define VEC_STORE3(val) \
	VEC_STORE1(val.s0) \
	VEC_STORE1(val.s1) \
	VEC_STORE1(val.s2)
#define VEC_STORE4(val) \
	VEC_STORE2(val.lo) \
	VEC_STORE2(val.hi)
#define VEC_STORE8(val) \
	VEC_STORE4(val.lo) \
	VEC_STORE4(val.hi)
#define VEC_STORE16(val) \
	VEC_STORE8(val.lo) \
	VEC_STORE8(val.hi)

#define __FUNC(SUFFIX, VEC_SIZE, TYPE, AS) \
  _CLC_OVERLOAD _CLC_DEF void vstore_half##SUFFIX(TYPE vec, size_t offset, AS half *mem) { \
    offset *= VEC_SIZE; \
    VEC_STORE##VEC_SIZE(vec) \
  }

#define FUNC(SUFFIX, VEC_SIZE, TYPE, AS) __FUNC(SUFFIX, VEC_SIZE, TYPE, AS)

#define __CLC_BODY "vstore_half.inc"
#include <clc/math/gentype.inc>

