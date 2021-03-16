org 0x0100
bits 16

%define BACKGROUND_COLOR 0x04
%define SQUARE_COLOR 0x00

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

_main:

    push cs
    pop ds
    pop es

    call enter_vga_mode

    push word BACKGROUND_COLOR
    call fill_screen
    add sp,2

    push word SQUARE_COLOR
    push word 10
    push word 20
    push word 20
    call do_square
    add sp,8
    
    ;push word 10
    ;push word 20
    ;push word 20
    ;push word grass_block
    ;call draw_tilemap
    ;add sp,8

    call await_keypress

    call leave_vga_mode

    mov ax,0x4C00
    int 0x21

await_keypress:

    mov ah,0x01
    int 0x21
    ret

%include "vga-draw.inc"