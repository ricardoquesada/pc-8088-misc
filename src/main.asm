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

        mov dx,hello
        mov ah,9
        int 0x21

        mov ax,0x4c00
        int 0x21

section .data

hello:
        db 'hello, world', 13, 10, '$'
