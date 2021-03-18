%ifndef _VGA_DRAW_INC
%define _VGA_DRAW_INC

%define VGA_GRAPHICS_MODE   0x13
%define VGA_SCREEN_WIDTH    320
%define VGA_SCREEN_HEIGHT   200
%define VGA_SEGMENT         0xA000

%define TILE_WIDTH      8
%define TILE_HEIGHT     8

%define TRANSPARENCY_ENTRY 0xff

%define VGA_TEXT_BITMAP_SEGMENT 0xF000
%define VGA_TEXT_BITMAP_OFFSET  0xFA6E
%define VGA_TEXT_WIDTH  8
%define VGA_TEXT_HEIGHT 8

%define BUFFER_BYTES (VGA_SCREEN_HEIGHT*VGA_SCREEN_WIDTH)
%define BUFFER_WORDS BUFFER_BYTES/2
%define BUFFER_DWORDS (BUFFER_BYTES/4)

%define BUFFER_SEGMENT 0xB000

; _cdecl enter_vga_mode()
; go to video mode 13h
enter_vga_mode:

    ;;we are going to hijack the segment above us for use i guess :shrug:
    mov ax,VGA_GRAPHICS_MODE
    int 0x10
    clc

.done:

    ret

; _cdecl leave_vga_mode()
; return to mode 03h
leave_vga_mode:

    mov ax,0x03
    int 0x10

    ret

; _cdecl draw()
; draw the back buffer to the display
draw:

    push ds
    push es

    push word BUFFER_SEGMENT
    pop ds

    push VGA_SEGMENT
    pop es

    xor si,si
    xor di,di

    mov cx,BUFFER_WORDS
    rep movsw

    pop es
    pop ds
    ret

; _cdecl fill_screen(uint8_t color)
; fill the vga screen with the given color
fill_screen:

    push bp
    mov bp,sp
    push es

    push BUFFER_SEGMENT
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

; _cdecl do_pixel(uint16_t abs_x, uint16_t abs_y, uint16_t sf, uint8_t color)
; draw a square at the given coordinate, using the given scaling factor
; if scaling factor is 1, draw a single pixel
do_pixel:

    push bp
    mov bp,sp    
    push es
    push bx

    ; if this pixel is supposed to be transparent, just skip the routine
    mov al,byte [bp+10]
    cmp al,TRANSPARENCY_ENTRY
    je .done

    push BUFFER_SEGMENT
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

.done:

    pop bx
    pop es
    pop bp
    ret

; _cdecl draw_tilemap(tilemap *tm, uint16_t x, uint16_t y, uint16_t sf)
; draw the given tilemap data at the requested x,y coordinate
; sf: scaling factor (used to increase the draw size of the tiles)
; e.g. tiles are 8 pixels wide. with a scale factor of 16, tiles will be drawn 128 pixels wide in total
draw_tilemap:

    push bp
    mov bp,sp
    push bx
    push si

    mov si,word [bp+4]          ; *tm goes in si for reading
    mov cx,TILE_HEIGHT          ; tile height goes in cx
    mov dx,word [bp+8]          ; y coordinate into dx

.rows:

    mov ax,word [bp+6]          ; x coordinate into ax

    push cx
    push dx

    mov cx,TILE_WIDTH

.columns:

    push ax
    push cx
    push dx

    mov bx,word [ds:si]
    push bx                         ; color value
    mov bx,word [bp+10]
    push bx                         ; scaling factor
    push dx                         ; y coordinate
    push ax                         ; x coordinate
    call do_pixel
    add sp,8

    inc si

    pop dx
    pop cx
    pop ax
    add ax,word [bp+10]
    loop .columns

    pop dx
    pop cx

    add dx,word [bp+10]         ; add scaling-factor to dx
    loop .rows

    pop si
    pop bx
    pop bp
    ret

; _cdecl draw_box(uint16_t x, uint16_t y, uint16_t w, uint16_t h, uint16_t thiccness, uint8_t color)
; draw a box on the screen
; x1,y1  -------  x2,y1
;       |       |
;       |       |
; x1,y2  -------  x2,y2

draw_box:

    push bp
    mov bp,sp

    mov dx,word [bp+4]      ; x
    add dx,word [bp+8]      ; w
    inc dx
    mov word [x2],dx

    mov dx,word [bp+6]      ; y
    add dx,word [bp+10]     ; h
    inc dx
    mov word [y2],dx

.horz_line_one:
    
    push word [bp+14]       ; color value
    push word [bp+12]       ; thiccness
    mov dx,word [x2]
    push dx                 ; x2
    push word [bp+6]        ; y1
    push word [bp+4]        ; x1
    call horz_line
    add sp,10

.horz_line_two:

    push word [bp+14]       ; color
    push word [bp+12]       ; thiccness
    push word [x2]          ; x2
    push word [y2]          ; y2
    push word [bp+4]        ; x1
    call horz_line
    add sp,10

.vert_line_one:

    push word [bp+14]       ; color
    push word [bp+12]       ; thiccness
    push word [y2]          ; y2
    push word [bp+6]        ; y1
    push word [bp+4]        ; x1
    call vert_line
    add sp,10

.vert_line_two:

    push word [bp+14]       ; color
    push word [bp+12]       ; thiccness
    inc word [y2]
    push word [y2]          ; y2
    push word [bp+6]        ; y1
    push word [x2]          ; x2
    call vert_line
    add sp,10

    pop bp
    ret

x2 dw 0
y2 dw 0

; _cdecl do_frect(uint16_t x_pos, uint16_t y_pos, uint16_t width, uint16_t height, uint8_t fillColor)
; draw a filled rectangle at the requested x,y coordinate
do_frect:

    push bp
    mov bp,sp
    push es
    push bx

    push BUFFER_SEGMENT
    pop es

    ; skip transparent rectangles
    mov al,byte [bp+12]
    cmp al,TRANSPARENCY_ENTRY
    je .done

    mov cx,word [bp+10]    ; height value in cx
    mov dx,word [bp+6]     ; y coordinate in dx

.rows:

    push cx
    push dx

    mov cx,word [bp+8]      ; width value into cx

    ; compute y offset
    mov ax,VGA_SCREEN_WIDTH
    mul dx
    xchg dx,ax

    mov bx,word [bp+4]      ; x coordinate into bx
    add bx,dx               ; add the y offset

.columns:

    mov al,byte [bp+12]
    mov byte [es:bx],al     ; store the color attribute
    inc bx

    loop .columns

    pop dx
    pop cx
    inc dx

    loop .rows

.done:

    pop bx
    pop es

    pop bp
    ret

; _cdecl vga_putc(uint16_t x, uint16_t y, uint8_t char, uint8_t color)
; print a character of text to the screen at coordinate x,y
vga_putc:

    push bp
    mov bp,sp

    ; preserve
    push ds
    push es
    push bx
    push si

    ; get the character data index into ds:si
    push VGA_TEXT_BITMAP_SEGMENT
    pop ds

    push BUFFER_SEGMENT
    pop es

    xor dx,dx
    mov dl,byte [bp+8]
    mov ax,VGA_TEXT_HEIGHT
    mul dx                  ; the character value is at bp+8, the color is at bp+9
    xchg dx,ax
    add dx,VGA_TEXT_BITMAP_OFFSET
    
    mov si,dx

    mov cx,VGA_TEXT_HEIGHT
    mov dx,word [bp+6]                  ; y coordinate

.rows:

    push cx
    push dx

    mov cx,VGA_TEXT_WIDTH

    mov ax,VGA_SCREEN_WIDTH
    mul dx
    xchg dx,ax                  ; compute y offset in video memory

    mov bx,word [bp+4]      ; x coordinate
    add bx,dx               ; add y offset

    mov al,byte [ds:si]     ; get the current bitmap entry
    mov dl,byte [bp+9]      ; color value

.columns:

    test al,0x80            ; see if the bottom bit is set
    jz .nopixel             ; if not, we don't have a pixel to draw
    mov byte [es:bx],dl

.nopixel:

    shl al,1            ; bit shift for next value
    inc bx              ; move to next draw location
    loop .columns

    pop dx
    pop cx

    inc si
    inc dx
    loop .rows

    ; restore
    pop si
    pop bx
    pop es
    pop ds

    pop bp
    ret

; _cdecl put_string(uint16_t x, uint16_t y, unsigned char *string, uint8_t color)
; write a null-terminated string to the display at the given coordinates
; special formatting characters (including linefeeds / carraige returns) are not considered
put_string:

    push bp
    mov bp,sp
    push si
    push bx

    mov si,word [bp+8]      ; pointer to string to display
    mov bx,word [bp+4]      ; x coordinate

.charloop:

    lodsb
    or al,al
    jz .done

    mov dl,al
    mov dh,byte [bp+10]     ; color attribute
    push dx
    push word [bp+6]        ; y coordinate
    push bx                 ; x coordinate
    call vga_putc           ; display the character
    add sp,6

    add bx,VGA_TEXT_WIDTH   ; move to next char position
    jmp .charloop           ; and print the next character

.done:

    pop bx
    pop si
    pop bp
    ret

; _cdecl horz_line(uint16_t x1, uint16_t y, uint16_t x2, uint16_t thiccness, uint8_t color)
; draw a horizontal line on the display using the given drawing color
horz_line:

    push bp
    mov bp,sp
    push es
    push bx

    push BUFFER_SEGMENT
    pop es

    xor cx,cx                   ; clear out cx
    mov dx,word [bp+6]          ; starting y location into dx

.thiccness:

    push cx
    push dx

    ; compute line length
    mov cx,word [bp+8]          ; end x location
    sub cx,word [bp+4]          ; subtract start x location

    mov ax,VGA_SCREEN_WIDTH
    mul dx
    xchg dx,ax                  ; as everywhere else, compute (y * SCREEN_WIDTH)

    mov bx,word [bp+4]
    add bx,dx                   ; abs = (y * SCREEN_WIDTH) + x
    mov al,byte [bp+12]         ; color attribute in al

.draw:

    mov byte [es:bx],al         ; store the color attribute
    inc bx
    loop .draw                  ; cx contains line length

    pop dx
    pop cx
    inc cx

    test cx,0x01                ; odd numbered row
    jz .even

    add dx,cx                   ; add the value in cx to dx
    jmp .next

.even:

    sub dx,cx                   ; subtract cx from dx             

.next:

    cmp cx,word [bp+10]
    jb .thiccness

    pop bx
    pop es
    pop bp
    ret

; _cdecl vert_line(uint16_t x, uint16_t y1, uint16_t y2, uint16_t thiccness, uint8_t color)
; draw a vertical line on the display
vert_line:

    push bp
    mov bp,sp
    push es
    push bx

    push BUFFER_SEGMENT
    pop es

    xor cx,cx                   ; clear out cx
    mov dx,word [bp+4]          ; starting x location into dx

.thiccness:

    push cx
    push dx

    ; compute line length
    mov cx,word [bp+8]          ; end y location
    mov bx,word [bp+6]          ; starting y location into bx
    sub cx,bx
    mov ax,VGA_SCREEN_WIDTH
    mul bx                      ; compute for absolute y
    mov bx,ax                   ; multiplication gets stored in ax ugh

    pop dx
    add bx,dx                   ; abs = (y * SCREEN_WIDTH) + x
    mov al,byte [bp+12]         ; color attribute in al

.draw:

    mov byte [es:bx],al         ; store the color attribute
    add bx,VGA_SCREEN_WIDTH    
    loop .draw                  ; cx contains line length

    pop cx
    inc cx

    test cx,0x01                ; odd numbered row
    jz .even

    add dx,cx                   ; add the value in cx to dx
    jmp .next

.even:

    sub dx,cx                   ; subtract cx from dx             

.next:

    cmp cx,word [bp+10]         ; see if we satisfied the thiccness
    jb .thiccness

    pop bx
    pop es
    pop bp
    ret

%endif