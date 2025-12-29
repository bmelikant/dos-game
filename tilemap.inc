%ifndef _TILEMAP_INC
%define _TILEMAP_INC

; structure to hold the metadata for the tilemap file
struc tilemap_metadata
	.tile_count 	resw 1		; a maximum of 65536 (16-bit int max) tiles
	.tile_pixels_x	resb 1		; max pixels x 255
	.tile_pixels_y	resb 1		; max pixels y 255
endstruc

; _cdecl load_tilemap_metadata(uint16_t fhandle, struct s_tmap_metadata *tilemap_meta)
; Read the metadata block at the beginning of the tilemap file
load_tilemap_metadata:

	push bp
	mov bp,sp

	mov bx,word [bp+4]					; file handle
	mov dx,word [bp+6]					; pointer to struct
	mov cx,tilemap_metadata_size		; size of struct

	xor ax,ax
	mov ah,0x3f
	int 0x21

	pop bp
	ret


; _cdecl read_tilemap(uint16_t fhandle, )
; 
; open the requested tilemap file for reading
read_tilemap:

	push bp
	mov bp,sp

	pop bp

%endif