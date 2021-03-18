org 0x0100
bits 16

%define EDITOR_BACKGROUND       50h
%define BACKGROUND_COLOR        04h
%define FONT_COLOR              77h
%define EDITOR_SELECTED_COLOR   0fh
    
    jmp _main


grass_block:

db 02h,02h,02h,02h,02h,02h,02h,02h,02h,02h
db 02h,06h,02h,06h,06h,06h,02h,06h,02h,02h
db 02h,06h,06h,06h,06h,06h,06h,06h,02h,06h
db 06h,06h,06h,06h,14h,06h,14h,06h,14h,06h
db 14h,06h,14h,06h,06h,06h,06h,06h,18h,06h
db 06h,06h,06h,06h,18h,06h,18h,06h,06h,06h
db 06h,14h,06h,18h,06h,14h,06h,06h,06h,18h
db 06h,06h,06h,06h,06h,06h,06h,06h,18h,06h
db 06h,06h,14h,06h,14h,06h,06h,06h,06h,06h
db 06h,06h,06h,06h,06h,06h,06h,06h,06h,06h

; data area
editor_current_x dw 0
editor_current_y dw 0

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
    push word 170                   ; 170 pixels high
    push word 170                   ; 170 pixels wide
    push word 20                    ; y coordinate
    push word 10                    ; x coordinate
    call do_frect
    add sp,10


    ; draw the current tile map
    push word 16                    ; scale tile map up by 16
    push word 25                    ; y coordinate
    push word 15                    ; x coordinate
    push word grass_block           ; tile to draw
    call draw_tilemap
    add sp,8

    ; compute the starting and ending points for the bounds box
    mov dx,word [editor_current_x]      ; add the x offset
    mov ax,16                           ; scaling factor
    mul dx
    add ax,15
    push ax                             ; save the x location onto the stack

    mov dx,word [editor_current_y]      ;
    mov ax,16
    mul dx                      ; compute y position
    add ax,25

    pop dx                      ; restore the x value back into dx

    push word 0fh               ; color
    push word 1                 ; thiccness
    push word 14                ; height
    push word 14                ; width
    push word ax                ; y loc is in ax
    push word dx                ; x loc in dx
    call draw_box
    add sp,12

    pop bp
    ret

await_keypress:

    mov ah,0x07
    int 0x21

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

.column_down:

    ; increase the y location of the draw box, up to a max of 10
    cmp word [editor_current_y],9
    jb .increment_editor_y
    xor dx,dx
    mov word [editor_current_y],dx
    jmp .done

.increment_editor_y:

    inc word [editor_current_y]
    jmp .done

.column_up:

    cmp word [editor_current_y],0
    jg .decrement_editor_y
    mov word [editor_current_y],9
    jmp .done

.decrement_editor_y:

    dec word [editor_current_y]
    jmp .done

.column_left:

    cmp word [editor_current_x],0
    jg .decrement_editor_x
    mov word [editor_current_x],9
    jmp .done

.decrement_editor_x:

    dec word [editor_current_x]
    jmp .done

.column_right:

    cmp word [editor_current_x],9
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

    ret

%include "vga-draw.inc"

editor_title: db 'TILE EDITOR',0
tile_buffer: times 100 db 0xff