bits 16

add bx, [bx + si]
add bx, [bp]
add bx, [bp]
add cx, [bx + 2]
add bh, [bp + si + 4]
add di, [bp + di + 6]
add [bx + si], bx
add [bp], bx
add [bp], bx
add [bx + 2], cx
add [bp + si + 4], bh
add [bp + di + 6], di
add ax, [bp]
add al, [bx + si]
add ax, bx
add al, ah
add ax, 1000
add al, 226
add al, 9
