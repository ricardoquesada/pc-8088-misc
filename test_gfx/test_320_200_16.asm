; Demonstration of how to write an entire .EXE format program as a .OBJ
; file to be linked. Tested with the VAL free linker.
; To build:
;    nasm -fobj objexe.asm
;    val objexe.obj,objexe.exe;
; To test:
;    objexe
; (should print `hello, world')

bits    16
cpu     8086

extern ZTimerOn, ZTimerOff, ZTimerReport

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; CODE
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .text
..start:
        mov     ax,data                         ;init segments
        mov     ds,ax                           ; DS=ES: same segment
        mov     es,ax                           ; SS: stack
        mov     ax,stack
        cli                                     ;disable interrupts while
        mov     ss,ax                           ; setting the stack pointer
        mov     sp,stacktop
        sti

;        mov al, 0b0001_0000                    ;40x25, text, color, bright
;        mov dx, 0x3d8
;        out dx, al


        call    ZTimerOn                        ;test ram memory
        call    paint_ram
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        mov     ax,0x0009
        int     0x10


        call    ZTimerOn                        ;test video memory
        call    paint_screen
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        call    ZTimerOn

        call    load_file

        call    ZTimerOff

        mov     ax,data
        mov     ds,ax
        call    print_msg

        call    wait_key

        mov     ax,0x0002
        int     0x10

        call    ZTimerReport

        mov     ax,0x4c00
        int     0x21


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
paint_screen:

        mov     cx,8000                         ;bank #0
        mov     al,0xee

        mov     bx,0xb800
        mov     es,bx
        xor     di,di                           ;es:di: destination
        rep     stosb


        mov     cx,8000                         ;bank #1
        mov     al,0x12

        mov     bx,0xb800
        mov     es,bx
        mov     di,0x2000                       ;es:di: destination
        rep     stosb


        mov     cx,8000                         ;bank #2
        mov     al,0x34

        mov     bx,0xb800
        mov     es,bx
        mov     di,0x4000                       ;es:di: destination
        rep     stosb


        mov     cx,8000                         ;bank #3
        mov     al,0x56

        mov     bx,0xb800
        mov     es,bx
        mov     di,0x6000                       ;es:di: destination
        rep     stosb
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
paint_ram:

        mov     cx,8000                         ;bank #0
        mov     al,0xee

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep     stosb


        mov     cx,8000                         ;bank #1
        mov     al,0x12

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep     stosb


        mov     cx,8000                         ;bank #2
        mov     al,0x34

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep     stosb


        mov     cx,8000                         ;bank #3
        mov     al,0x56

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep     stosb
        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
print_msg:
        mov     dx,hello
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_key:
        xor     ah,ah                           ;Function number: get key
        int     0x16                            ;Call BIOS keyboard interrupt
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
load_file:
        mov     ah,0x3d                         ;open file
        mov     al,0
        mov     dx,file_320_200_16
        int     0x21
        jc      error

        mov     bx,ax                           ;file handle
        mov     cx,32768                        ;bytes to read
        xor     dx,dx
        mov     ax,0xb800
        mov     ds,ax                           ;dst: ds:dx b800:0000
        mov     ah,0x3f                         ;read file
        int     0x21
        jc      error

        mov     ah,0x3e                         ;close fd
        int     0x21
        jc      error

        ret

error:
        mov     dx,error_msg
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data

hello:
        db      'hello, world', 13, 10, '$'

error_msg:
        db      'error', 13, 10, '$'

file_320_200_16:
        db      '32020016.raw', 0

file_320_200_4:
        db      '32020004.raw', 0

file_160_200_16:
        db      '16020016.raw', 0

file_640_200_4:
        db      '64020004.raw', 0

file_640_200_2:
        db      '64020002.raw', 0


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
