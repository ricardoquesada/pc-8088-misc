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

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Structs and others
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

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

        call    init_video

        call    paint_screen

        call    wait_key

        mov     ax,0x0002                       ;text mode 80x25
        int     0x10

        mov     ax,0x4c00
        int     0x21                            ;exit to DOS

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
paint_screen:
        cld
        mov     cx,8000                         ;number of loops

        mov     di,0x0000                       ;es:di destination for stos
        mov     ax,0xb800
        mov     es,ax

        mov     si,image                        ;ds:si attributes

.l0:
        mov     al,222                          ;char
        lodsb                                   ;attribute
        xchg    ah,al

        stosw                                   ;put in screen memory

        loop    .l0

        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
init_video:
        mov     dx,0x3d8
        mov     al,0b0010_1001                  ;text mode, 80x25, color
        out     dx,al

        mov     si,crt6845_3d4_160_100          ;text 160x100 16 colors
        call    do_out


        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
do_out:
        call    video_off

        mov     cx,16                           ;16 registers in total
        mov     dx,0x3d4
        sub     bx,bx                           ;counter for 3d4 idx

.l0:
        mov     al,bl
        out     dx,al

        lodsb
        inc     dx                              ;3d5
        out     dx,al

        dec     dx                              ;3d4
        inc     bx                              ;next register idx

        loop    .l0

        call    video_on

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
video_on:
	    in      al,0x70                         ;enable NMI
	    or      al,0x80
	    out     0x70,al

	    sti                                     ;enable interrupts

	    mov     dx,0x3d8
	    mov     al,0b0000_1001                  ;no blink. intensity only
	    out     dx,al

        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
video_off:

        mov     dx,0x3d8                        ;disable video
        mov     al,1
        out     dx,al

	    cli                                     ;no interrupts
        in      al,0x70                         ;disable NMI
        and     al,0x7F
	    out     0x70,al

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_key:
        xor     ah,ah                           ;Function number: get key
        int     0x16                            ;Call BIOS keyboard interrupt
        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data

crt6845_3d4_160_100:
        ;     0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
        db 0x71, 0x50, 0x5a, 0x0a, 0x7f, 0x06, 0x64, 0x70, 0x02, 0x01, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; 160x100

image:
       incbin "image160100.bin" 

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
