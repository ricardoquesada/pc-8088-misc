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

        call    wait_key

        call    test_border

        call    wait_key

        mov     ax,0x0002                       ;text mode 80x25
        int     0x10

        mov     ax,0x4c00
        int     0x21                            ;exit to DOS


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
test_border:
        call    init_screen

        mov     dx,0x3da
        mov     al,3                            ;select CRT mode control
        out     dx,al

        mov     dx,0x3de
        mov     al,0b0001_0100                  ;enable border color, enable 16 colors
        out     dx,al

        call    wait_key

.repeat:
        call    wait_vert_retrace

        call    anim_border_color

        in      al,0x60
        cmp     al,1
        jne     .repeat

        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
init_screen:
        mov     ax,0x0009                       ;320x200 16 colors
        int     0x10

        call    set_charset

        call    update_palette


        mov     cx,C64_SCREEN_SIZE
        mov     si,c64_screen
        mov     dx,0x0100                       ;row=1, column=0

.repeat:
        mov     ah,2                            ;set cursor position
        mov     bh,0                            ;page 0
        int     0x10

        inc     dl
        cmp     dl,40                           ;reached column 40
        jb      .l0
        inc     dh                              ;inc row
        mov     dl,0                            ;reset column

.l0:
        mov     ah,0x0a                         ;write char
        lodsb                                   ;char to write
        mov     bh,0                            ;page to write to
        mov     bl,9                            ;color: light blue

        push    dx
        push    cx

        mov     cx,1                            ;number of times to write to
        int     0x10

        pop     cx
        pop     dx

        loop    .repeat

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
update_palette:
        mov     dx,0x3da                        ;select border color register
        mov     al,2
        out     dx,al

        add     dx,4                            ;change border color
        mov     al,9                            ;light blue
        out     dx,al


        sub     dx,4
        mov     al,0x10                         ;select color=0
        out     dx,al                           ;select palette register

        add     dx,4
        mov     al,1                            ;color 0 is blue now (before it was black)
        out     dx,al

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
set_charset:
        push    ds
        mov     dx,ds

        sub     ax,ax
        mov     ds,ax

        mov     ax,c64_charset                  ;charset 0-127 for graphics mode
        mov     [0x44 * 4 + 0],ax
        mov     [0x44 * 4 + 2],dx

        mov     ax,c64_charset + 128 * 8        ;charset 128-255 for graphics mode
        mov     [0x1f * 4 + 0],ax
        mov     [0x1f * 4 + 2],dx

        pop     ds

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
anim_border_color:
        int     3
        mov     cx,260                          ;260 scan lines

        mov     dx,0x3da

.repeat:

.wait_retrace_finish:                           ;if horizontal retrace already started, wait
        in      al,dx                           ; until it finishes
        test    al,1
        jnz     .wait_retrace_finish

.wait_retrace_start:                            ;wait for horizontal retrace start
        in      al,dx
        test    al,1
        jz      .wait_retrace_start


        mov     al,2                            ;select border color
        out     dx,al

        add     dx,4
        mov     al,[border_color]               ;select color for border
        and     al,0x0f
        out     dx,al                           ;change border
        inc     byte [border_color]

        sub     dx,4

        loop    .repeat

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
wait_vert_retrace:
        mov     dx,0x3da

.wait_retrace_finish:                           ;if retrace already started, wait
        in      al,dx                           ; until it finishes
        test    al,8
        jnz     .wait_retrace_finish

.wait_retrace_start:
        in      al,dx                           ;wait until start of the retrace
        test    al,8
        jz      .wait_retrace_start

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data

border_color:
        db 0

c64_screen:
           ;0123456789012345678901234567890123456789
        db '    **** COMMODORE 64 BASIC V2 ****     '
        db ' 64K RAM SYSTEM  38911 BASIC BYTES FREE '
        db '                                        '
        db 'READY.                                  '
C64_SCREEN_SIZE equ $ - c64_screen

c64_charset:
        incbin 'c64_charset-charset.bin'
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
