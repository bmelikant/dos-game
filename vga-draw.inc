%ifndef _VGA_DRAW_INC
%define _VGA_DRAW_INC

%define VGA_GRAPHICS_MODE   0x13
%define VGA_SCREEN_WIDTH    320
%define VGA_SCREEN_HEIGHT   200
%define VGA_SEGMENT         0xA000

%define TILE_WIDTH      10
%define TILE_HEIGHT     10

enter_vga_mode:

    mov ax,VGA_GRAPHICS_MODE
    int 0x10
    ret

leave_vga_mode:

    mov ax,0x03
    int 0x10
    ret

; fill_screen(uint8_t color)
; fill the vga screen with the given color
fill_screen:

    push bp
    mov bp,sp
    push es

    push VGA_SEGMENT
    pop es

    mov cx,(VGA_SCREEN_WIDTH*VGA_SCREEN_HEIGHT)/2
    mov dl,byte [bp+4]                              ; color value goes into DL
    mov dh,dl                                       ; and DH. make it more efficient by writing words at a time

    push bx
    xor bx,bx                       ; bx is callee-preserved

.fill:

    mov word [es:bx],dx             ; store the color attribute at the given address
    add bx,2                        ; and increase BX
    loop .fill

    pop bx
    pop es
    pop bp
    ret

; do_square(uint16_t abs_x, uint16_t abs_y, uint16_t sf, uint8_t color)
; draw a square at the given coordinate, using the given scaling factor
; if scaling factor is 1, draw a single pixel
do_square:

    push bp
    mov bp,sp    
    push es
    push bx

    push VGA_SEGMENT
    pop es

    mov dx,word [bp+6]          ; absolute y in dx
    mov cx,word [bp+8]          ; scaling factor in cx

.row:

    push dx
    push cx

    mov ax,VGA_SCREEN_WIDTH     ; and the width of the screen
    mul dx

    mov bx,word [bp+4]
    add bx,ax                   ; mem_loc = (abs_y * VGA_SCREEN_WIDTH) + abs_x

    mov cx,word [bp+8]          ; scale factor in cx (again)

.column:

    mov al,byte [bp+10]         ; color attribute in al
    mov byte [es:bx],al         ; store it back
    inc bx

    loop .column

    pop cx
    pop dx

    inc dx
    loop .row

    pop bx
    pop es
    pop bp
    ret



; draw_tilemap(tilemap *tm, uint16_t x, uint16_t y, uint16_t sf)
; draw the given tilemap data at the requested x,y coordinate
; sf: scaling factor (used to increase the draw size of the tiles)
; e.g. tiles are 8 pixels wide. with a scale factor of 16, tiles will be drawn 128 pixels wide in total
draw_tilemap:

    push bp
    mov bp,sp
    push bx

    mov si,word [bp+4]          ; *tm goes in si for reading
    mov cx,TILE_HEIGHT          ; tile height goes in cx
    mov dx,word [bp+8]          ; y coordinate into dx
    mov ax,word [bp+2]          ; x coordinate into ax

.rows:

    push cx
    push dx

    mov cx,TILE_WIDTH

.columns:

    push ax

    mov bx,word [bp+10]
    push bx
    push dx
    push ax
    mov bx,word [bp+4]
    push bx
    call do_square
    add sp,8

    pop ax
    add ax,word [bp+10]
    loop .columns

    pop dx
    pop cx

    add dx,word [bp+10]         ; add scaling-factor to dx
    loop .rows

    push bx
    pop bp
    ret

%endif