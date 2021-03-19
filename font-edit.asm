bits 16
org 0x0100

%define VSEGMENT    0xB800
%define BACK_BUFFER SCREEN_WORDS
%define TEXT_WIDTH  8
%define TEXT_HEIGHT 8
%define CHARACTER_SIZE (TEXT_WIDTH*TEXT_HEIGHT)/8
%define TOTAL_CHARCTERS 256

%define VWIDTH          320
%define VHEIGHT         200
%define BITS_PER_PIXEL  2
%define PIXELS_PER_BYTE (8/BITS_PER_PIXEL)
%define SCREEN_WORDS (VWIDTH*VHEIGHT)/PIXELS_PER_BYTE

%define BYTES_X     VWIDTH/PIXELS_PER_BYTE

%define BACKCOLOR 5555h
%define FORECOLOR 2
%define EDITOR_X 12
%define EDITOR_Y 12
%define EDITOR_SCALE 2          ; 2 bytes per editor pixel
%define EDITOR_ROWS 16

%define EDITOR_ABS_START (EDITOR_Y * (BYTES_X)) + (EDITOR_X / PIXELS_PER_BYTE)

    jmp begin


%define MAX_PALETTE_INDEX 3
palette   db 0               ; pointer to current palette entry
palettes: db 00h,10h,01h,11h

character db 0          ; current character entry

begin:

    push cs
    pop ax
    mov ds,ax
    mov es,ax

    mov ax,0x04
    int 0x10

.loop:

    call clrscr
    call draw
    call input

    or al,al
    jz .loop

    mov ax,0x03
    int 0x10

    mov ax,0x4c00
    int 0x21

; _cdecl draw_chareditor()
; draw the currently selected character on the display, scaled up 10x
draw_chareditor:

    push es
    push bx
    push si
    push di

    push VSEGMENT
    pop es
    mov di,BACK_BUFFER

    mov si,charmap
    xor bx,bx
    mov bl,byte [character]
    mov ax,8
    mul bx
    xchg bx,ax                  ; locate the character map entry

    mov dx,EDITOR_ABS_START
    mov cx,

    pop di
    pop si
    pop bx
    pop es

    ret

; _cdecl clrscr()
; clear the display using the color BACKGROUND
clrscr:

    push es
    push di

    push VSEGMENT
    pop es
    mov di,BACK_BUFFER

    mov dx,BACKCOLOR
    mov cx,SCREEN_WORDS

.clrloop:

    mov word [es:di],dx
    add di,2
    loop .clrloop

    pop di
    pop es
    ret

; _cdecl draw()
; draw the current back buffer to the screen
draw:

    push ds
    push es
    push si
    push di

    push VSEGMENT
    pop ax
    mov ds,ax
    mov es,ax

    mov si,BACK_BUFFER
    xor di,di
    mov cx,SCREEN_WORDS

    rep movsw

    pop di
    pop si
    pop es
    pop ds

    ret

; _cdecl set_palette(uint8_t palette_idx)
; if palette index is 0, set low intensity grb palette
; 1 = high intensity cmw palette
set_palette:

    push bp
    mov bp,sp
    push bx

    mov bx,0x0100
    mov bl,byte [bp+4]
    mov ah,0x0b
    int 0x10

    mov bl,byte [bp+4]
    test bl,0x10
    jz .low_intensity

    mov bx,0x0010
    int 0x10
    jmp .done

.low_intensity:

    xor bx,bx
    int 0x10

.done:

    pop bx
    pop bp
    ret

input:

    mov ah,0x07
    int 0x21

    cmp al,'p'
    je .switch_palette

    cmp al,'q'
    je .quit

    jmp .done

.quit:

    mov ax,1
    jmp .return

.switch_palette:

    mov dl,byte [palette]
    cmp dl,MAX_PALETTE_INDEX
    je .zero_palette

    inc dl
    mov byte [palette],dl
    jmp .palette

.zero_palette:

    xor dl,dl
    mov byte [palette],dl

.palette:

    mov di,palettes
    xor bx,bx
    mov bl,byte [palette]

    xor dx,dx
    mov dl,byte [di+bx]
    push dx
    call set_palette
    add sp,2

.done: xor ax,ax
.return:

    ret


charmap times CHARACTER_SIZE*TOTAL_CHARCTERS db 0