org 0x0100
bits 16

%define TILE_PIXEL_WIDTH    8
%define TILE_PIXEL_HEIGHT   8

%define X_TILES (320/TILE_PIXEL_WIDTH)
%define Y_TILES (200/TILE_PIXEL_HEIGHT)

%define VMEM_SEGMENT       0xA000
%define PIXELS_PER_ROW     320

    jmp start

grass_block:

db 02h,02h,02h,02h,02h,02h,02h,02h
db 02h,06h,02h,06h,06h,06h,02h,06h
db 02h,06h,06h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,14h,06h,14h,06h
db 14h,06h,14h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,18h,06h,18h,06h
db 06h,14h,06h,18h,06h,14h,06h,06h
db 06h,06h,06h,06h,06h,06h,06h,06h

dirt_block:

db 06h,14h,06h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,06h,06h,18h,06h
db 18h,06h,06h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,14h,06h,14h,06h
db 14h,06h,14h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,18h,06h,18h,06h
db 06h,14h,06h,18h,06h,14h,06h,06h
db 06h,06h,06h,06h,06h,06h,06h,06h

start:

    push cs
    pop ds
    pop es

    mov ax,0x0013
    int 0x10

    call demo

    mov ah,0x01
    int 0x21

    mov ax,0x0003
    int 0x10

    mov ax,0x4c00
    int 0x21

demo:

    mov cx,X_TILES
    xor dx,dx

.fill_loop:

    push word 16
    push word dx
    push word grass_block
    call draw_tile
    add sp,6

    add dx,8
    loop .fill_loop

    mov cx,Y_TILES
    sub cx,3
    mov ax,24

.fill_lines:

    push cx
    mov cx,X_TILES
    xor dx,dx

.fill_dirt_blocks:

    push word ax
    push word dx
    push word dirt_block
    call draw_tile
    add sp,6

    add dx,8
    loop .fill_dirt_blocks

    pop cx
    add ax,8
    loop .fill_lines

    ret

; draw_tile(tile_data *tile, uint16_t tile_x, uint16_t tile_y)
; draw the given tile at the provided x,y tile coordinate
draw_tile:

    push bp
    mov bp,sp

    push es
    push ax
    push bx
    push cx
    push dx

    push VMEM_SEGMENT
    pop es

    mov si,word [bp+4]          ; get the pointer to the tile data into si
    mov cx,TILE_PIXEL_HEIGHT    ; number of pixels y per tile in CX
    mov dx,word [bp+8]          ; we need to multiply the tile coordinate by the number of y pixels per tile          

.row:

    push cx
    push dx

    mov ax,PIXELS_PER_ROW
    mul dx
    xchg dx,ax                  ; get the absolute y start into cx

    ; get x start into bx and adjust for absolute y
    mov bx,word [bp+6]
    add bx,dx

    mov cx,TILE_PIXEL_WIDTH

.column:

    mov al,byte [ds:si]         ; get the next color byte
    mov byte [es:bx],al         ; store it into the destination location
    inc bx
    inc si

    loop .column                ; draw TILE_PIXEL_WIDTH bytes

    pop dx
    pop cx

    inc dx
    loop .row

    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop bp
    ret