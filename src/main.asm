; Demonstration of how to write an entire .EXE format program as a .OBJ
; file to be linked. Tested with the VAL free linker.
; To build:
;    nasm -fobj objexe.asm
;    val objexe.obj,objexe.exe;
; To test:
;    objexe
; (should print `hello, world')

bits 16

section .text
        global __start
__start:

        ; these 3 lines are only needed for .EXEs, but not .COMs
        mov ax, ss
        mov ds, ax ; DS=ES=SS in small model .EXEs and in tiny model .COMs
        mov es, ax

;        mov al, 0b0001_0000     ;40x25, text, color, bright
;        mov dx, 0x3d8
;        out dx, al

        mov ax, 0x0009
        int 0x10


        mov cx, 8000                    ; bank #0
        mov al, 0xee

        mov bx, 0xb800
        mov es, bx
        xor di, di                      ; es:di: destination
rep     stosb


        mov cx, 8000                    ; bank #1
        mov al, 0x12

        mov bx, 0xb800
        mov es, bx
        mov di, 0x2000                  ; es:di: destination
rep     stosb


        mov cx, 8000                    ; bank #2
        mov al, 0x34

        mov bx, 0xb800
        mov es, bx
        mov di, 0x4000                  ; es:di: destination
rep     stosb


        mov cx, 8000                    ; bank #3
        mov al, 0x56

        mov bx, 0xb800
        mov es, bx
        mov di, 0x6000                  ; es:di: destination
rep     stosb

        xor  ah,ah                      ;Function number: get key
        int  0x16                       ;Call BIOS keyboard interrupt

;        mov dx,hello
;        mov ah,9
;        int 0x21

        mov ax,0x4c00
        int 0x21

section .data

hello:
        db 'hello, world', 13, 10, '$'
