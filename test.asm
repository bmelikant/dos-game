;---------------------------------------------------------------------------;
; assemble: nasm -o test.obj test.asm                                       ;
; link: wine optlink.exe -ENTRY:_begin -SU:WINDOWS -FIXE test.obj,test.exe  ;
;---------------------------------------------------------------------------;
bits 16

section .data

message db "Hello, world!$"

section .text

[global begin]
begin:

    push cs
    pop ax
    mov ds,ax
    mov es,ax

    mov ah,0x09
    mov dx,message
    int 0x21

    mov ax,0x4c00
    int 0x21
