; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse2      | FileCheck %s --check-prefix=SSE --check-prefix=SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse4.2    | FileCheck %s --check-prefix=SSE --check-prefix=SSE42
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx       | FileCheck %s --check-prefix=AVX --check-prefix=AVX1
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx2      | FileCheck %s --check-prefix=AVX --check-prefix=AVX2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512f   | FileCheck %s --check-prefix=AVX --check-prefix=AVX512 --check-prefix=AVX512F

;
; General cases - packing of vector comparison to legal vector result types
;

define <16 x i8> @vselect_packss_v16i16(<16 x i16> %a0, <16 x i16> %a1, <16 x i8> %a2, <16 x i8> %a3) {
; SSE2-LABEL: vselect_packss_v16i16:
; SSE2:       # BB#0:
; SSE2-NEXT:    pcmpeqw %xmm3, %xmm1
; SSE2-NEXT:    pcmpeqw %xmm2, %xmm0
; SSE2-NEXT:    packsswb %xmm1, %xmm0
; SSE2-NEXT:    pand %xmm0, %xmm4
; SSE2-NEXT:    pandn %xmm5, %xmm0
; SSE2-NEXT:    por %xmm4, %xmm0
; SSE2-NEXT:    retq
;
; SSE42-LABEL: vselect_packss_v16i16:
; SSE42:       # BB#0:
; SSE42-NEXT:    pcmpeqw %xmm3, %xmm1
; SSE42-NEXT:    pcmpeqw %xmm2, %xmm0
; SSE42-NEXT:    packsswb %xmm1, %xmm0
; SSE42-NEXT:    pblendvb %xmm0, %xmm4, %xmm5
; SSE42-NEXT:    movdqa %xmm5, %xmm0
; SSE42-NEXT:    retq
;
; AVX1-LABEL: vselect_packss_v16i16:
; AVX1:       # BB#0:
; AVX1-NEXT:    vextractf128 $1, %ymm1, %xmm4
; AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm5
; AVX1-NEXT:    vpcmpeqw %xmm4, %xmm5, %xmm4
; AVX1-NEXT:    vpcmpeqw %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpacksswb %xmm4, %xmm0, %xmm0
; AVX1-NEXT:    vpblendvb %xmm0, %xmm2, %xmm3, %xmm0
; AVX1-NEXT:    vzeroupper
; AVX1-NEXT:    retq
;
; AVX2-LABEL: vselect_packss_v16i16:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpcmpeqw %ymm1, %ymm0, %ymm0
; AVX2-NEXT:    vextracti128 $1, %ymm0, %xmm1
; AVX2-NEXT:    vpacksswb %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    vpblendvb %xmm0, %xmm2, %xmm3, %xmm0
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
;
; AVX512-LABEL: vselect_packss_v16i16:
; AVX512:       # BB#0:
; AVX512-NEXT:    vpcmpeqw %ymm1, %ymm0, %ymm0
; AVX512-NEXT:    vpmovsxwd %ymm0, %zmm0
; AVX512-NEXT:    vpmovdb %zmm0, %xmm0
; AVX512-NEXT:    vpblendvb %xmm0, %xmm2, %xmm3, %xmm0
; AVX512-NEXT:    vzeroupper
; AVX512-NEXT:    retq
  %1 = icmp eq <16 x i16> %a0, %a1
  %2 = sext <16 x i1> %1 to <16 x i8>
  %3 = and <16 x i8> %2, %a2
  %4 = xor <16 x i8> %2, <i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1>
  %5 = and <16 x i8> %4, %a3
  %6 = or <16 x i8> %3, %5
  ret <16 x i8> %6
}

define <16 x i8> @vselect_packss_v16i32(<16 x i32> %a0, <16 x i32> %a1, <16 x i8> %a2, <16 x i8> %a3) {
; SSE2-LABEL: vselect_packss_v16i32:
; SSE2:       # BB#0:
; SSE2-NEXT:    pcmpeqd %xmm7, %xmm3
; SSE2-NEXT:    pcmpeqd %xmm6, %xmm2
; SSE2-NEXT:    packssdw %xmm3, %xmm2
; SSE2-NEXT:    pcmpeqd %xmm5, %xmm1
; SSE2-NEXT:    pcmpeqd %xmm4, %xmm0
; SSE2-NEXT:    packssdw %xmm1, %xmm0
; SSE2-NEXT:    packsswb %xmm2, %xmm0
; SSE2-NEXT:    movdqa {{[0-9]+}}(%rsp), %xmm1
; SSE2-NEXT:    pand %xmm0, %xmm1
; SSE2-NEXT:    pandn {{[0-9]+}}(%rsp), %xmm0
; SSE2-NEXT:    por %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE42-LABEL: vselect_packss_v16i32:
; SSE42:       # BB#0:
; SSE42-NEXT:    movdqa {{[0-9]+}}(%rsp), %xmm8
; SSE42-NEXT:    pcmpeqd %xmm7, %xmm3
; SSE42-NEXT:    pcmpeqd %xmm6, %xmm2
; SSE42-NEXT:    packssdw %xmm3, %xmm2
; SSE42-NEXT:    pcmpeqd %xmm5, %xmm1
; SSE42-NEXT:    pcmpeqd %xmm4, %xmm0
; SSE42-NEXT:    packssdw %xmm1, %xmm0
; SSE42-NEXT:    packsswb %xmm2, %xmm0
; SSE42-NEXT:    pblendvb %xmm0, {{[0-9]+}}(%rsp), %xmm8
; SSE42-NEXT:    movdqa %xmm8, %xmm0
; SSE42-NEXT:    retq
;
; AVX1-LABEL: vselect_packss_v16i32:
; AVX1:       # BB#0:
; AVX1-NEXT:    vextractf128 $1, %ymm3, %xmm6
; AVX1-NEXT:    vextractf128 $1, %ymm1, %xmm7
; AVX1-NEXT:    vpcmpeqd %xmm6, %xmm7, %xmm6
; AVX1-NEXT:    vpcmpeqd %xmm3, %xmm1, %xmm1
; AVX1-NEXT:    vpackssdw %xmm6, %xmm1, %xmm1
; AVX1-NEXT:    vextractf128 $1, %ymm2, %xmm3
; AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm6
; AVX1-NEXT:    vpcmpeqd %xmm3, %xmm6, %xmm3
; AVX1-NEXT:    vpcmpeqd %xmm2, %xmm0, %xmm0
; AVX1-NEXT:    vpackssdw %xmm3, %xmm0, %xmm0
; AVX1-NEXT:    vpacksswb %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpblendvb %xmm0, %xmm4, %xmm5, %xmm0
; AVX1-NEXT:    vzeroupper
; AVX1-NEXT:    retq
;
; AVX2-LABEL: vselect_packss_v16i32:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpcmpeqd %ymm3, %ymm1, %ymm1
; AVX2-NEXT:    vpcmpeqd %ymm2, %ymm0, %ymm0
; AVX2-NEXT:    vpacksswb %ymm1, %ymm0, %ymm0
; AVX2-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,2,1,3]
; AVX2-NEXT:    vextracti128 $1, %ymm0, %xmm1
; AVX2-NEXT:    vpacksswb %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    vpand %xmm4, %xmm0, %xmm1
; AVX2-NEXT:    vpandn %xmm5, %xmm0, %xmm0
; AVX2-NEXT:    vpor %xmm0, %xmm1, %xmm0
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
;
; AVX512-LABEL: vselect_packss_v16i32:
; AVX512:       # BB#0:
; AVX512-NEXT:    vpcmpeqd %zmm1, %zmm0, %k1
; AVX512-NEXT:    vpternlogd $255, %zmm0, %zmm0, %zmm0 {%k1} {z}
; AVX512-NEXT:    vpmovdb %zmm0, %xmm0
; AVX512-NEXT:    vpblendvb %xmm0, %xmm2, %xmm3, %xmm0
; AVX512-NEXT:    vzeroupper
; AVX512-NEXT:    retq
  %1 = icmp eq <16 x i32> %a0, %a1
  %2 = sext <16 x i1> %1 to <16 x i8>
  %3 = and <16 x i8> %2, %a2
  %4 = xor <16 x i8> %2, <i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1>
  %5 = and <16 x i8> %4, %a3
  %6 = or <16 x i8> %3, %5
  ret <16 x i8> %6
}

define <16 x i8> @vselect_packss_v16i64(<16 x i64> %a0, <16 x i64> %a1, <16 x i8> %a2, <16 x i8> %a3) {
; SSE2-LABEL: vselect_packss_v16i64:
; SSE2:       # BB#0:
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm7
; SSE2-NEXT:    pshufd {{.*#+}} xmm8 = xmm7[1,0,3,2]
; SSE2-NEXT:    pand %xmm7, %xmm8
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm6
; SSE2-NEXT:    pshufd {{.*#+}} xmm7 = xmm6[1,0,3,2]
; SSE2-NEXT:    pand %xmm6, %xmm7
; SSE2-NEXT:    packssdw %xmm8, %xmm7
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm5
; SSE2-NEXT:    pshufd {{.*#+}} xmm6 = xmm5[1,0,3,2]
; SSE2-NEXT:    pand %xmm5, %xmm6
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm4
; SSE2-NEXT:    pshufd {{.*#+}} xmm5 = xmm4[1,0,3,2]
; SSE2-NEXT:    pand %xmm4, %xmm5
; SSE2-NEXT:    packssdw %xmm6, %xmm5
; SSE2-NEXT:    packssdw %xmm7, %xmm5
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm3
; SSE2-NEXT:    pshufd {{.*#+}} xmm4 = xmm3[1,0,3,2]
; SSE2-NEXT:    pand %xmm3, %xmm4
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm2
; SSE2-NEXT:    pshufd {{.*#+}} xmm3 = xmm2[1,0,3,2]
; SSE2-NEXT:    pand %xmm2, %xmm3
; SSE2-NEXT:    packssdw %xmm4, %xmm3
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm1
; SSE2-NEXT:    pshufd {{.*#+}} xmm2 = xmm1[1,0,3,2]
; SSE2-NEXT:    pand %xmm1, %xmm2
; SSE2-NEXT:    pcmpeqd {{[0-9]+}}(%rsp), %xmm0
; SSE2-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[1,0,3,2]
; SSE2-NEXT:    pand %xmm0, %xmm1
; SSE2-NEXT:    packssdw %xmm2, %xmm1
; SSE2-NEXT:    packssdw %xmm3, %xmm1
; SSE2-NEXT:    packsswb %xmm5, %xmm1
; SSE2-NEXT:    movdqa {{[0-9]+}}(%rsp), %xmm0
; SSE2-NEXT:    pand %xmm1, %xmm0
; SSE2-NEXT:    pandn {{[0-9]+}}(%rsp), %xmm1
; SSE2-NEXT:    por %xmm0, %xmm1
; SSE2-NEXT:    movdqa %xmm1, %xmm0
; SSE2-NEXT:    retq
;
; SSE42-LABEL: vselect_packss_v16i64:
; SSE42:       # BB#0:
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm7
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm6
; SSE42-NEXT:    packssdw %xmm7, %xmm6
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm5
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm4
; SSE42-NEXT:    packssdw %xmm5, %xmm4
; SSE42-NEXT:    packssdw %xmm6, %xmm4
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm3
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm2
; SSE42-NEXT:    packssdw %xmm3, %xmm2
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm1
; SSE42-NEXT:    pcmpeqq {{[0-9]+}}(%rsp), %xmm0
; SSE42-NEXT:    packssdw %xmm1, %xmm0
; SSE42-NEXT:    packssdw %xmm2, %xmm0
; SSE42-NEXT:    packsswb %xmm4, %xmm0
; SSE42-NEXT:    movdqa {{[0-9]+}}(%rsp), %xmm1
; SSE42-NEXT:    pand %xmm0, %xmm1
; SSE42-NEXT:    pandn {{[0-9]+}}(%rsp), %xmm0
; SSE42-NEXT:    por %xmm1, %xmm0
; SSE42-NEXT:    retq
;
; AVX1-LABEL: vselect_packss_v16i64:
; AVX1:       # BB#0:
; AVX1-NEXT:    vextractf128 $1, %ymm7, %xmm8
; AVX1-NEXT:    vextractf128 $1, %ymm3, %xmm9
; AVX1-NEXT:    vpcmpeqq %xmm8, %xmm9, %xmm8
; AVX1-NEXT:    vpcmpeqq %xmm7, %xmm3, %xmm3
; AVX1-NEXT:    vpackssdw %xmm8, %xmm3, %xmm8
; AVX1-NEXT:    vextractf128 $1, %ymm6, %xmm7
; AVX1-NEXT:    vextractf128 $1, %ymm2, %xmm3
; AVX1-NEXT:    vpcmpeqq %xmm7, %xmm3, %xmm3
; AVX1-NEXT:    vpcmpeqq %xmm6, %xmm2, %xmm2
; AVX1-NEXT:    vpackssdw %xmm3, %xmm2, %xmm2
; AVX1-NEXT:    vpackssdw %xmm8, %xmm2, %xmm2
; AVX1-NEXT:    vextractf128 $1, %ymm5, %xmm3
; AVX1-NEXT:    vextractf128 $1, %ymm1, %xmm6
; AVX1-NEXT:    vpcmpeqq %xmm3, %xmm6, %xmm3
; AVX1-NEXT:    vpcmpeqq %xmm5, %xmm1, %xmm1
; AVX1-NEXT:    vpackssdw %xmm3, %xmm1, %xmm1
; AVX1-NEXT:    vextractf128 $1, %ymm4, %xmm3
; AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm5
; AVX1-NEXT:    vpcmpeqq %xmm3, %xmm5, %xmm3
; AVX1-NEXT:    vpcmpeqq %xmm4, %xmm0, %xmm0
; AVX1-NEXT:    vpackssdw %xmm3, %xmm0, %xmm0
; AVX1-NEXT:    vpackssdw %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpacksswb %xmm2, %xmm0, %xmm0
; AVX1-NEXT:    vpand {{[0-9]+}}(%rsp), %xmm0, %xmm1
; AVX1-NEXT:    vpandn {{[0-9]+}}(%rsp), %xmm0, %xmm0
; AVX1-NEXT:    vpor %xmm0, %xmm1, %xmm0
; AVX1-NEXT:    vzeroupper
; AVX1-NEXT:    retq
;
; AVX2-LABEL: vselect_packss_v16i64:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpcmpeqq %ymm7, %ymm3, %ymm3
; AVX2-NEXT:    vpcmpeqq %ymm6, %ymm2, %ymm2
; AVX2-NEXT:    vpackssdw %ymm3, %ymm2, %ymm2
; AVX2-NEXT:    vpermq {{.*#+}} ymm2 = ymm2[0,2,1,3]
; AVX2-NEXT:    vpcmpeqq %ymm5, %ymm1, %ymm1
; AVX2-NEXT:    vpcmpeqq %ymm4, %ymm0, %ymm0
; AVX2-NEXT:    vpackssdw %ymm1, %ymm0, %ymm0
; AVX2-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,2,1,3]
; AVX2-NEXT:    vpacksswb %ymm2, %ymm0, %ymm0
; AVX2-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,2,1,3]
; AVX2-NEXT:    vextracti128 $1, %ymm0, %xmm1
; AVX2-NEXT:    vpacksswb %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    vpand {{[0-9]+}}(%rsp), %xmm0, %xmm1
; AVX2-NEXT:    vpandn {{[0-9]+}}(%rsp), %xmm0, %xmm0
; AVX2-NEXT:    vpor %xmm0, %xmm1, %xmm0
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
;
; AVX512-LABEL: vselect_packss_v16i64:
; AVX512:       # BB#0:
; AVX512-NEXT:    vextracti32x4 $3, %zmm2, %xmm6
; AVX512-NEXT:    vpextrq $1, %xmm6, %rcx
; AVX512-NEXT:    vextracti32x4 $3, %zmm0, %xmm7
; AVX512-NEXT:    vpextrq $1, %xmm7, %rdx
; AVX512-NEXT:    xorl %eax, %eax
; AVX512-NEXT:    cmpq %rcx, %rdx
; AVX512-NEXT:    movq $-1, %rcx
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm8
; AVX512-NEXT:    vmovq %xmm6, %rdx
; AVX512-NEXT:    vmovq %xmm7, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm6
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm8 = xmm6[0],xmm8[0]
; AVX512-NEXT:    vextracti32x4 $2, %zmm2, %xmm7
; AVX512-NEXT:    vpextrq $1, %xmm7, %rdx
; AVX512-NEXT:    vextracti32x4 $2, %zmm0, %xmm6
; AVX512-NEXT:    vpextrq $1, %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm9
; AVX512-NEXT:    vmovq %xmm7, %rdx
; AVX512-NEXT:    vmovq %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm6
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm6 = xmm6[0],xmm9[0]
; AVX512-NEXT:    vinserti128 $1, %xmm8, %ymm6, %ymm8
; AVX512-NEXT:    vextracti128 $1, %ymm2, %xmm7
; AVX512-NEXT:    vpextrq $1, %xmm7, %rdx
; AVX512-NEXT:    vextracti128 $1, %ymm0, %xmm6
; AVX512-NEXT:    vpextrq $1, %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm9
; AVX512-NEXT:    vmovq %xmm7, %rdx
; AVX512-NEXT:    vmovq %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm6
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm6 = xmm6[0],xmm9[0]
; AVX512-NEXT:    vpextrq $1, %xmm2, %rdx
; AVX512-NEXT:    vpextrq $1, %xmm0, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm7
; AVX512-NEXT:    vmovq %xmm2, %rdx
; AVX512-NEXT:    vmovq %xmm0, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm0
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm0 = xmm0[0],xmm7[0]
; AVX512-NEXT:    vinserti128 $1, %xmm6, %ymm0, %ymm0
; AVX512-NEXT:    vinserti64x4 $1, %ymm8, %zmm0, %zmm0
; AVX512-NEXT:    vpmovqd %zmm0, %ymm8
; AVX512-NEXT:    vextracti32x4 $3, %zmm3, %xmm2
; AVX512-NEXT:    vpextrq $1, %xmm2, %rdx
; AVX512-NEXT:    vextracti32x4 $3, %zmm1, %xmm6
; AVX512-NEXT:    vpextrq $1, %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm7
; AVX512-NEXT:    vmovq %xmm2, %rdx
; AVX512-NEXT:    vmovq %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm2
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm2 = xmm2[0],xmm7[0]
; AVX512-NEXT:    vextracti32x4 $2, %zmm3, %xmm6
; AVX512-NEXT:    vpextrq $1, %xmm6, %rdx
; AVX512-NEXT:    vextracti32x4 $2, %zmm1, %xmm7
; AVX512-NEXT:    vpextrq $1, %xmm7, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm0
; AVX512-NEXT:    vmovq %xmm6, %rdx
; AVX512-NEXT:    vmovq %xmm7, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm6
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm0 = xmm6[0],xmm0[0]
; AVX512-NEXT:    vinserti128 $1, %xmm2, %ymm0, %ymm2
; AVX512-NEXT:    vextracti128 $1, %ymm3, %xmm0
; AVX512-NEXT:    vpextrq $1, %xmm0, %rdx
; AVX512-NEXT:    vextracti128 $1, %ymm1, %xmm6
; AVX512-NEXT:    vpextrq $1, %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm7
; AVX512-NEXT:    vmovq %xmm0, %rdx
; AVX512-NEXT:    vmovq %xmm6, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm0
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm0 = xmm0[0],xmm7[0]
; AVX512-NEXT:    vpextrq $1, %xmm3, %rdx
; AVX512-NEXT:    vpextrq $1, %xmm1, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    movl $0, %edx
; AVX512-NEXT:    cmoveq %rcx, %rdx
; AVX512-NEXT:    vmovq %rdx, %xmm6
; AVX512-NEXT:    vmovq %xmm3, %rdx
; AVX512-NEXT:    vmovq %xmm1, %rsi
; AVX512-NEXT:    cmpq %rdx, %rsi
; AVX512-NEXT:    cmoveq %rcx, %rax
; AVX512-NEXT:    vmovq %rax, %xmm1
; AVX512-NEXT:    vpunpcklqdq {{.*#+}} xmm1 = xmm1[0],xmm6[0]
; AVX512-NEXT:    vinserti128 $1, %xmm0, %ymm1, %ymm0
; AVX512-NEXT:    vinserti64x4 $1, %ymm2, %zmm0, %zmm0
; AVX512-NEXT:    vpmovqd %zmm0, %ymm0
; AVX512-NEXT:    vinserti64x4 $1, %ymm0, %zmm8, %zmm0
; AVX512-NEXT:    vpmovdb %zmm0, %xmm0
; AVX512-NEXT:    vpblendvb %xmm0, %xmm4, %xmm5, %xmm0
; AVX512-NEXT:    vzeroupper
; AVX512-NEXT:    retq
  %1 = icmp eq <16 x i64> %a0, %a1
  %2 = sext <16 x i1> %1 to <16 x i8>
  %3 = and <16 x i8> %2, %a2
  %4 = xor <16 x i8> %2, <i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1>
  %5 = and <16 x i8> %4, %a3
  %6 = or <16 x i8> %3, %5
  ret <16 x i8> %6
}

;
; PACKSS case
;

define <16 x i8> @vselect_packss(<16 x i16> %a0, <16 x i16> %a1, <16 x i8> %a2, <16 x i8> %a3) {
; SSE2-LABEL: vselect_packss:
; SSE2:       # BB#0:
; SSE2-NEXT:    pcmpeqw %xmm3, %xmm1
; SSE2-NEXT:    pcmpeqw %xmm2, %xmm0
; SSE2-NEXT:    packsswb %xmm1, %xmm0
; SSE2-NEXT:    pand %xmm0, %xmm4
; SSE2-NEXT:    pandn %xmm5, %xmm0
; SSE2-NEXT:    por %xmm4, %xmm0
; SSE2-NEXT:    retq
;
; SSE42-LABEL: vselect_packss:
; SSE42:       # BB#0:
; SSE42-NEXT:    pcmpeqw %xmm3, %xmm1
; SSE42-NEXT:    pcmpeqw %xmm2, %xmm0
; SSE42-NEXT:    packsswb %xmm1, %xmm0
; SSE42-NEXT:    pblendvb %xmm0, %xmm4, %xmm5
; SSE42-NEXT:    movdqa %xmm5, %xmm0
; SSE42-NEXT:    retq
;
; AVX1-LABEL: vselect_packss:
; AVX1:       # BB#0:
; AVX1-NEXT:    vextractf128 $1, %ymm1, %xmm4
; AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm5
; AVX1-NEXT:    vpcmpeqw %xmm4, %xmm5, %xmm4
; AVX1-NEXT:    vpcmpeqw %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpacksswb %xmm4, %xmm0, %xmm0
; AVX1-NEXT:    vpblendvb %xmm0, %xmm2, %xmm3, %xmm0
; AVX1-NEXT:    vzeroupper
; AVX1-NEXT:    retq
;
; AVX2-LABEL: vselect_packss:
; AVX2:       # BB#0:
; AVX2-NEXT:    vpcmpeqw %ymm1, %ymm0, %ymm0
; AVX2-NEXT:    vextracti128 $1, %ymm0, %xmm1
; AVX2-NEXT:    vpacksswb %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    vpblendvb %xmm0, %xmm2, %xmm3, %xmm0
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
;
; AVX512-LABEL: vselect_packss:
; AVX512:       # BB#0:
; AVX512-NEXT:    vpcmpeqw %ymm1, %ymm0, %ymm0
; AVX512-NEXT:    vextracti128 $1, %ymm0, %xmm1
; AVX512-NEXT:    vpacksswb %xmm1, %xmm0, %xmm0
; AVX512-NEXT:    vpblendvb %xmm0, %xmm2, %xmm3, %xmm0
; AVX512-NEXT:    vzeroupper
; AVX512-NEXT:    retq
  %1 = icmp eq <16 x i16> %a0, %a1
  %2 = sext <16 x i1> %1 to <16 x i16>
  %3 = shufflevector <16 x i16> %2, <16 x i16> undef, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  %4 = shufflevector <16 x i16> %2, <16 x i16> undef, <8 x i32> <i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  %5 = tail call <16 x i8> @llvm.x86.sse2.packsswb.128(<8 x i16> %3, <8 x i16> %4)
  %6 = and <16 x i8> %5, %a2
  %7 = xor <16 x i8> %5, <i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1>
  %8 = and <16 x i8> %7, %a3
  %9 = or <16 x i8> %6, %8
  ret <16 x i8> %9
}
declare <16 x i8> @llvm.x86.sse2.packsswb.128(<8 x i16>, <8 x i16>)
