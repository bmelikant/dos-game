org 0x0100
bits 16

%define EDITOR_BACKGROUND       50h
%define BACKGROUND_COLOR        04h
%define FONT_COLOR              77h
%define EDITOR_SELECTED_COLOR   0fh

%define TILEMAP_SCALE 16

%define EDITOR_POSITION_X   5
%define EDITOR_POSITION_Y   10
%define EDITOR_WIDTH        136
%define EDITOR_HEIGHT       136

%define TILE_SCALE 16
%define TILE_EDITOR_X 9
%define TILE_EDITOR_Y 14
%define TILE_EDITOR_BOX_WIDTH 14
%define TILE_EDITOR_BOX_HEIGHT TILE_EDITOR_BOX_WIDTH
%define TILE_EDITOR_BOX_THICCNESS 1
%define TILE_EDITOR_BOX_COLOR 0fh
%define TEDIT_MAX_PIXEL_X 7
%define TEDIT_MAX_PIXEL_Y 7

%define PALETTE_POS_X 145
%define PALETTE_POS_Y 10
%define PALETTE_SQUARE_SZ 8
%define PALETTE_ROWS 16
%define PALETTE_COLUMNS 16

    jmp _main

grass_block:

db 02h,02h,02h,02h,02h,02h,02h,02h
db 02h,06h,02h,06h,06h,06h,02h,06h
db 02h,06h,06h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,14h,06h,14h,06h
db 14h,06h,14h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,18h,06h,18h,06h
db 06h,14h,06h,18h,06h,14h,06h,06h
db 06h,06h,06h,06h,06h,06h,06h,06h

; data area
editor_current_x    db 0
editor_x_max db TEDIT_MAX_PIXEL_X
editor_current_y    db 0
editor_y_max db TEDIT_MAX_PIXEL_Y

palette_current_x   db 0
palette_x_max db PALETTE_COLUMNS - 1
palette_current_y   db 0
palette_y_max db PALETTE_ROWS - 1

selected_color  db  0

_main:

    push cs
    pop ax
    mov ds,ax
    mov es,ax

    call enter_vga_mode

.open_tiles:

    push word BACKGROUND_COLOR
    call fill_screen
    add sp,2

    call open_tilemap

    push word tilemap_filemeta
    push word [tilemap_fhandle]
    call load_tilemap_metadata
    add sp,4

    jnc .tile_editor

    call leave_vga_mode

    mov ah,0x09
    mov dx,tilemap_error
    int 0x21

    jmp terminate

.tile_editor:

    push word BACKGROUND_COLOR
    call fill_screen
    add sp,2

    call draw_tile_editor       ; draw the current state of the tile editor
    ;call draw_palette           ; and the color selector
    call draw
    call await_keypress         ; get user input

    or ax,ax
    jz .tile_editor             ; as long as return code is zero, continue executing

    call leave_vga_mode

    mov ax,0x4C00
    int 0x21

; _cdecl draw_tile_editor()
; draw the current tile editor to the screen
draw_tile_editor:

    push bp
    mov bp,sp

    ; print the editor title
    xor dx,dx
    mov dl,FONT_COLOR

    push dx
    push word editor_title
    push word 1
    push word 10
    call put_string
    add sp,8

    ; draw tile editor border
    push word EDITOR_BACKGROUND     ; rectangle color
    push word EDITOR_HEIGHT         ; height
    push word EDITOR_WIDTH          ; width
    push word EDITOR_POSITION_Y     ; y coordinate
    push word EDITOR_POSITION_X     ; x coordinate
    call do_frect
    add sp,10


    ; draw the current tile map
    push word TILE_SCALE                    ; scale tile map up by 16
    push word TILE_EDITOR_Y                 ; y coordinate
    push word TILE_EDITOR_X                 ; x coordinate
    push word grass_block           ; tile to draw
    call draw_tilemap
    add sp,8

    ; compute the starting and ending points for the bounds box
    xor dx,dx
    mov dl,byte [editor_current_x]      ; current selected editor tile
    mov ax,TILE_SCALE                   ; scaling factor
    mul dx
    add ax,TILE_EDITOR_X                ; add the x offset of the tile map
    push ax                             ; save the x location onto the stack

    xor dx,dx
    mov dl,byte [editor_current_y]      ;
    mov ax,TILE_SCALE
    mul dx                      ; compute y position
    add ax,TILE_EDITOR_Y

    pop dx                      ; restore the x value back into dx

    push word TILE_EDITOR_BOX_COLOR
    push word TILE_EDITOR_BOX_THICCNESS                     
    push word TILE_EDITOR_BOX_HEIGHT
    push word TILE_EDITOR_BOX_WIDTH
    push word ax                ; y loc is in ax
    push word dx                ; x loc in dx
    call draw_box
    add sp,12

    ; print the editor title
    xor dx,dx
    mov dl,FONT_COLOR

    push dx
    push word current_color
    push word 151
    push word 13
    call put_string
    add sp,8

    ; draw the current color attribute
    xor dx,dx
    mov dl,byte [selected_color]

    push dx                           ; color attribute
    push word 10                            ; height
    push word 30                            ; width
    push word 160                           ; y loc
    push word 10                            ; x loc
    call do_frect
    add sp,10

    xor dx,dx
    mov dl,byte [selected_color]

    push word 0fh
    push word 161                ; y location
    push word 13                ; x location
    push dx                     ; save the current color
    call display_hex_number
    add sp,8

    xor dx,dx
    mov dx,word [tilemap_filemeta]
    push word 0fh
    push word 181
    push word 13
    push dx

    call display_hex_number
    add sp,8

    pop bp
    ret

draw_palette:

    push bp
    mov bp,sp

    xor bx,bx
    mov ax,PALETTE_POS_Y
    mov dx,PALETTE_POS_X
    mov cx,PALETTE_ROWS

.row:

    push cx
    mov cx,PALETTE_COLUMNS

.enter_loop:

    push dx
    push ax
    push cx

    push bx                         ; current color is in cx
    push word PALETTE_SQUARE_SZ     ; y size in pixels
    push word PALETTE_SQUARE_SZ     ; x size in pixels
    push ax                         ; y pos is in ax
    push dx                         ; x pos is in dx
    call do_frect
    add sp,10

    pop cx
    pop ax
    pop dx

    inc bx
    add dx,PALETTE_SQUARE_SZ
    loop .enter_loop

    pop cx

    mov dx,PALETTE_POS_X
    add ax,PALETTE_SQUARE_SZ

    loop .row

    pop bp
    ret

await_keypress:

    push di

    mov bx,editor_current_x
    mov di,editor_current_y

.key:

    mov ah,0x07
    int 0x21

    ; if the character code returned is zero, it's an extended code
    or al,al
    jz .get_extended_code

    cmp al,'s'
    je .column_down         ; move down on either the palette or the tile map

    cmp al,'w'
    je .column_up           ; up on the palette or tile map

    cmp al,'a'
    je .column_left         ; left

    cmp al,'d'
    je .column_right        ; right

    cmp al,0x20
    je .switch_pixel_color  ; spacebar

    cmp al,'q'
    je .send_exit_code      ; exit the editor

.skip:

    jmp .done

.get_extended_code:

    int 0x21

    cmp al,0x4b
    je .dec_color       ; left arrow

    cmp al,0x4d
    je .inc_color       ; right arrow

    jmp .done

.dec_color:

    mov dl,byte [selected_color]
    or dl,dl
    jz .done

    dec dl
    mov byte [selected_color],dl

    jmp .done

.inc_color:

    mov dl,byte [selected_color]
    cmp dl,255
    je .done

    inc dl
    mov byte [selected_color],dl
    jmp .done

.column_down:

    ; increase the y location of the draw box, up to a max of 10
    mov dl,byte [editor_current_y]
    cmp dl,byte [editor_current_y+1]
    jb .increment_editor_y
    xor dx,dx
    mov byte [di],dl
    jmp .done

.increment_editor_y:

    inc byte [editor_current_y]
    jmp .done

.column_up:

    mov dl,byte [editor_current_y]
    cmp dl,0
    jg .decrement_editor_y
    mov al,byte [editor_current_y+1]
    mov byte [editor_current_y],al
    jmp .done

.decrement_editor_y:

    dec byte [editor_current_y]
    jmp .done

.column_left:

    mov dl,byte [editor_current_x]
    cmp dl,0
    jg .decrement_editor_x
    mov al,byte [editor_current_x+1]
    mov byte [editor_current_x],al
    jmp .done

.decrement_editor_x:

    dec byte [editor_current_x]
    jmp .done

.column_right:

    mov dl,byte [editor_current_x]
    cmp dl,byte [editor_current_x+1]
    jb .increment_editor_x
    mov byte [editor_current_x],0
    jmp .done

.increment_editor_x:

    inc byte [editor_current_x]
    jmp .done

.switch_pixel_color:

    xor ax,ax
    xor dx,dx

    mov al,byte [editor_x_max]        ; max columns
    inc al
    mov dl,byte [editor_current_y]    ; current row
    mul dl                            ; multiply

    add al,byte [editor_current_x]      ; add the column offset

    ; AX contains the offset into the current block. Switch the color of the pixel with the new color
    mov bx,grass_block
    add bx,ax

    mov dl,byte [selected_color]
    mov byte [bx],dl

.done:

    xor ax,ax
    jmp .exitfn

.send_exit_code:

    mov ax,1

.exitfn:

    pop di
    ret

open_tilemap:

    mov dx,tilemap_filename
    mov ah,0x3d
    mov al,01000000b        ; open file read-only

    int 0x21
    jc .error

    mov word [tilemap_fhandle],ax
    ret

.error:

    call leave_vga_mode

    mov ah,0x09
    mov dx,tilemap_error
    int 0x21

terminate:

    xor ax,ax
    int 0x16

    mov ax,0x4C00
    int 0x21


%include "vga-draw.inc"
%include "tilemap.inc"

editor_title: db 'TILE EDITOR',0
current_color: db 'CURRENT COLOR',0

tilemap_error db 'An error occurred loading the requested tilemap$',0
tilemap_read_error db 'An error occured reading the requested tilemap$'
tilemap_filename: db 'TILES.DAT',0
tilemap_fhandle dw 0

tilemap_filemeta:
.tile_count     dw 0
.tile_pixels_x  db 0
.tile_pixels_y  db 0

tile_buffer: times 100 db 0xff