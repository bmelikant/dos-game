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

%define PALETTE_POS_X 5
%define PALETTE_POS_Y 140
%define PALETTE_SQUARE_SZ 6
%define PALETTE_ROWS 8
%define PALETTE_COLUMNS 32

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

change_palette      db 0




_main:

    push cs
    pop ax
    mov ds,ax
    mov es,ax

    call enter_vga_mode

.tile_editor:

    push word BACKGROUND_COLOR
    call fill_screen
    add sp,2

    call draw_tile_editor       ; draw the current state of the tile editor
    call draw_palette           ; and the color selector
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

    ; set up whether we are changing the palette value or the tile pixel
    mov al,byte [change_palette]
    or al,al
    jz .change_tile_pos

    mov bx,palette_current_x
    mov di,palette_current_y
    jmp .key

.change_tile_pos:

    mov bx,editor_current_x
    mov di,editor_current_y

.key:

    mov ah,0x07
    int 0x21

    cmp al,'t'
    je .toggle

    cmp al,'s'
    je .column_down

    cmp al,'w'
    je .column_up

    cmp al,'a'
    je .column_left

    cmp al,'d'
    je .column_right

    cmp al,'q'
    je .send_exit_code

.skip:

    jmp .done

.toggle:

    mov al,byte [change_palette]
    or al,al
    jz .toggle_on

    mov byte [change_palette],0
    jmp .done

.toggle_on:

    mov byte [change_palette],1
    jmp .done

.column_down:

    ; increase the y location of the draw box, up to a max of 10
    mov byte [di],dl
    cmp dl,byte [di+1]
    jb .increment_editor_y
    xor dx,dx
    mov byte [di],dl
    jmp .done

.increment_editor_y:

    inc byte [di]
    jmp .done

.column_up:

    cmp byte [editor_current_y],0
    jg .decrement_editor_y
    mov al,byte [editor_current_y+1]
    mov byte [editor_current_y],al
    jmp .done

.decrement_editor_y:

    dec word [editor_current_y]
    jmp .done

.column_left:

    cmp word [editor_current_x],0
    jg .decrement_editor_x
    mov word [editor_current_x],TEDIT_MAX_PIXEL_X
    jmp .done

.decrement_editor_x:

    dec word [editor_current_x]
    jmp .done

.column_right:

    cmp word [editor_current_x],TEDIT_MAX_PIXEL_X
    jb .increment_editor_x
    mov word [editor_current_x],0
    jmp .done

.increment_editor_x:

    inc word [editor_current_x]

.done:

    xor ax,ax
    jmp .exitfn

.send_exit_code:

    mov ax,1

.exitfn:

    pop di
    ret

%include "vga-draw.inc"

editor_title: db 'TILE EDITOR',0
tile_buffer: times 100 db 0xff