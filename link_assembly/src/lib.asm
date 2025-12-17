global AddToAllBytes
global SumAllBytes
global StupidZeroAllBytes
global Read1x
global Read2x
global Read3x
global Read4x
global Write1x
global Write2x
global Read1Write1
global Read2Write1
global Read2Write2
global Read128Bits2x
global Read256Bits2x
global ReadWithin
global ReadWithinUnaligned
global ReadBadL1

section .text

AddToAllBytes:
	xor rax, rax
.loop:
	add [rdi + rax], byte 1
	inc rax
	cmp rax, rsi
	jb .loop
	ret

SumAllBytes:
	xor rax, rax
	xor r8, r8
	xor r9, r9
.loop:
	movzx r9, byte [rdi + r8]
	add rax, r9
	inc r8
	cmp r8, rsi
	jb .loop
	ret

StupidZeroAllBytes:
	xor rax, rax
	xor r8, r8
.loop:
	inc rax
	cmp rax, rdi
	jb .loop
.loop2:
	sub rax, 1
	cmp rax, 0
	jnz .loop2
	add r8, rdi
	cmp r8, rsi
	jb .loop
	ret

Read1x:
	align 64
.loop:
	mov rax, [rdi]
	sub rsi, 1
	jnle .loop
	ret

Read2x:
	align 64
.loop:
	mov rax, [rdi]
	mov rax, [rdi]
	sub rsi, 2
	jnle .loop
	ret

Read3x:
	align 64
.loop:
	mov rax, [rdi]
	mov rax, [rdi]
	mov rax, [rdi]
	sub rsi, 3
	jnle .loop
	ret

Read4x:
	align 64
.loop:
	mov rax, [rdi]
	mov rax, [rdi]
	mov rax, [rdi]
	mov rax, [rdi]
	sub rsi, 4
	jnle .loop
	ret

Write1x:
	align 64
.loop:
	mov [rdi], rax
	sub rsi, 1
	jnle .loop
	ret

Write2x:
	align 64
.loop:
	mov [rdi], rax
	mov [rdi], rax
	sub rsi, 2
	jnle .loop
	ret

Read1Write1:
	align 64
	xor r8, r8
.loop:
	mov rax, [rdi]
	mov [rdi], r8
	sub rsi, 2
	jnle .loop
	ret

Read2Write1:
	align 64
	xor r8, r8
.loop:
	mov rax, [rdi]
	mov rax, [rdi]
	mov [rdi], r8
	sub rsi, 3
	jnle .loop
	ret

Read2Write2:
	align 64
	xor r8, r8
.loop:
	mov rax, [rdi]
	mov rax, [rdi]
	mov [rdi], r8
	mov [rdi], r8
	sub rsi, 4
	jnle .loop
	ret

Read128Bits2x:
	align 64
.loop:
	vmovdqu xmm0, [rdi]
	vmovdqu xmm1, [rdi + 16]
	sub rsi, 16
	jnle .loop
	ret

Read256Bits2x:
	align 64
.loop:
	vmovdqu ymm0, [rdi]
	vmovdqu ymm1, [rdi + 32]
	sub rsi, 32
	jnle .loop
	ret

;4 loads take two cycles (on zen2)
;no dependency chain is longer than 2, so we should be able to do the adds, movs, cmps simultaneously with the loads,
;keeping the load ports saturated
ReadWithin:
	align 64
	xor r8, r8
	xor r9, r9
	xor rax, rax
.loop:
	mov r9, rdi
	add r9, r8
	vmovdqu ymm0, [r9]
	vmovdqu ymm0, [r9 + 32]
	vmovdqu ymm0, [r9 + 64]
	vmovdqu ymm0, [r9 + 96]
	add r8, 128
	and r8, rsi
	add rax, 128
	cmp rax, 1073741824
	jne .loop
	ret

ReadWithinUnaligned:
	align 64
	xor r8, r8
	xor r9, r9
	xor rax, rax
.loop:
	mov r9, rdi
	add r9, r8
	vmovdqu ymm0, [r9 + 1]
	vmovdqu ymm0, [r9 + 33]
	vmovdqu ymm0, [r9 + 65]
	vmovdqu ymm0, [r9 + 97]
	add r8, 128
	and r8, rsi
	add rax, 128
	cmp rax, 1073741824
	jne .loop
	ret

ReadBadL1:
	align 64
	xor r8, r8
.loop:
	mov r9, rdi
	add r9, r8
	vmovdqu ymm0, [r9]
	vmovdqu ymm0, [r9]
	vmovdqu ymm0, [r9]
	vmovdqu ymm0, [r9]
	add r8, rsi
	cmp rdx, r8
	jnle .loop
	ret
