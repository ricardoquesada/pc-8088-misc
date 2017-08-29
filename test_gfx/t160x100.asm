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

        call    paint_screen

        call    do_test

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
        sub     bx,bx                           ;color
        sub     dx,dx                           ;inc color every line
.l0:
        mov     ah,bl                           ;attribute
        mov     al,221                          ;char
        stosw
        inc     dx
        cmp     dx,40                           ;inc color every 40 chars
        jne     .l1

        inc     bx                              ;inc color
        and     bl,0b0111_1111                  ;filter blinking attribute
        sub     dx,dx

.l1:
        loop    .l0

        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
do_test:
        mov     si,crt6845_3d4_a+16*4           ;table offset
        call    do_out
        call    wait_key

        mov     si,crt6845_3d4_a+16*5           ;table offset
        call    do_out
        call    wait_key

        mov     si,crt6845_3d4_a+16*6           ;table offset
        call    do_out
        call    wait_key

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

	    mov     dx,0x3D8
	    mov     al,9
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

; table used by Tandy 1000 HX BIOS by default
crt6845_3d4_a:
        ;     0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
        db 0x38, 0x28, 0x2d, 0x0a, 0x1f, 0x06, 0x19, 0x1c, 0x02, 0x07, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; modes 0,1 (40x25)
        db 0x71, 0x50, 0x5a, 0x0a, 0x1f, 0x06, 0x19, 0x1c, 0x02, 0x07, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; modes 2,3 (80x25)
        db 0x38, 0x28, 0x2d, 0x0a, 0x7f, 0x06, 0x64, 0x70, 0x02, 0x01, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; modes 4,5,6,8 (16k modes: 320x200 4, etc)
        db 0x71, 0x50, 0x5a, 0x0e, 0x3f, 0x06, 0x32, 0x38, 0x02, 0x03, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; modes 9,a (32k modes: 320x200 16, etc)

        db 0x38, 0x28, 0x2d, 0x0a, 0x7f, 0x06, 0x64, 0x70, 0x02, 0x01, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; 
        db 0x71, 0x50, 0x5a, 0x0a, 0x7f, 0x06, 0x64, 0x70, 0x02, 0x01, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; 160x100
        db 0x71, 0x50, 0x5a, 0x0a, 0xff, 0x06, 0xc8, 0xe0, 0x02, 0x00, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; 

; official table from Tandy 1000 HX Technical Rererence
crt6845_3d4_b:
        db 0x38, 0x28, 0x2d, 0x08, 0x1c, 0x01, 0x19, 0x1a, 0x02, 0x08, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00
        db 0x71, 0x50, 0x5a, 0x0e, 0x1c, 0x01, 0x19, 0x1a, 0x02, 0x08, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00
        db 0x38, 0x28, 0x2d, 0x08, 0x7f, 0x06, 0x64, 0x70, 0x02, 0x01, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00
        db 0x71, 0x50, 0x5a, 0x0e, 0x3f, 0x06, 0x32, 0x38, 0x02, 0x03, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
