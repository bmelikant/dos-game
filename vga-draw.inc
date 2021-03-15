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

; draw_tilemap(tilemap *tm, uint16_t x, uint16_t y, uint16_t sf)
; draw the given tilemap data at the requested x,y coordinate
; sf: scaling factor (used to increase the draw size of the tiles)
; e.g. tiles are 8 pixels wide. with a scale factor of 16, tiles will be drawn 128 pixels wide in total
draw_tilemap:

    push bp
    mov bp,sp

    push es
    push bx

    push VGA_SEGMENT
    pop es                      ; get the correct segment into ES

    mov si,word [bp+4]          ; *tm goes in si for reading
    mov cx,TILE_HEIGHT          ; tile height goes in cx
    mov dx,word [bp+8]          ; y coordinate into dx

.rows:

    push cx
    push dx

    mov ax,VGA_SCREEN_WIDTH
    mul dx
    mov dx,ax

    mov bx,word [bp+6]              ; x location into bx
    add bx,dx                       ; screen_loc = (y_loc * VGA_SCREEN_WIDTH) + x_loc -> bx = (dx * VGA_SCREEN_WIDTH) + bx

    mov cx,TILE_WIDTH

.columns:

    mov al,byte [ds:si]             ; get the color value
    inc si

    mov byte [es:bx],al             ; put the color in the destination byte
    inc bx

    loop .columns

    pop dx
    pop cx

    inc dx
    loop .rows

    pop bx
    pop es
    pop bp
    ret

%endif