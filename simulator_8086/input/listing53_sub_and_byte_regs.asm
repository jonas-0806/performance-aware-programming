bits 16

mov cx, 35 
mov bp, 230

mov al, 11
mov si, 0
init_loop_start:
	mov byte [bp + si], al
	sub al, 1
	add si, 7
	cmp si, cx
	jnz init_loop_start

mov dh, 255
mov si, cx
add_loop_start:
	sub si, 7
	sub dh, byte [bp + si]
	cmp si, 0
	jnz add_loop_start
