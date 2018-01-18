; PCjr Undocumented Diagnostics
; http://retro.moe

bits    16
cpu     8086

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; MACROS and CONSTANTS
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; CODE
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .text
..start:
        mov     ax,stack
        cli                                     ;disable interrupts while
        mov     ss,ax                           ; setting the stack pointer
        mov     sp,stacktop
        sti

        cld

        mov     ax,0x0001                       ;mode 40x25 color
        int     0x10

        mov     ax,0x0507                       ;page 7
        int     0x10

        call    main

        mov     ax,0x0001
        int     0x10

        mov     ax,4c00h
        int     21h                             ;exit to DOS


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
main:

        mov     ax,data
        mov     ds,ax

.loop:
        call    draw_screen

        mov     ah,0
        int     0x16                            ;wait for key

        cmp     ah,1                            ;escape?
        jne     .ok                             ;no, keep going then
        ret                                     ;exit if so

.ok:

        int     3
        mov     ah,al                           ;value to pass to int handler
        cmp     ah,0x40                         ;is it number?
        jb      .l1                             ;if so, don't "and" it
        and     ah,0b1101_1111                  ;convert to uppper case (that's what the tests expect)
.l1

        ;setup expected segments
        mov     bx,0x40
        mov     ds,bx                           ;ds = 0x40
        sub     bx,bx
        mov     es,bx                           ;es = 0

        mov     cx,64                           ;64 interrupts
        mov     di,0x0214

.next_intr:
        push    ax
        push    cx
        push    di
        push    ds
        push    es

        mov     al,cl
        out     0x10,al                         ;mfg flag = 64 -> 1

        cmp     word [es:di+2],0                ;segment is 0? running on emulator, skip
        je      .skip
        clc
        pushf                                   ;simulate int call
        call    far [es:di]                     ;call interrupt handler

.skip:
        pop     es
        pop     ds
        pop     di
        pop     cx
        pop     ax

        add     di,4                            ;next int
        loop    .next_intr


        mov     ah,0
        int     0x16                            ;wait for key after exit

        jmp     .loop

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
draw_screen:
        mov     ax,0x0001
        int     0x10

        mov     ax,0x0507                       ;page 7
        int     0x10

        mov     dx,0x020f                       ;col 2, col 15
        mov     bh,7                            ;page 7
        mov     ah,2
        int     0x10                            ;set cursor position

        push    ds
        push    es

        mov     cx,HELP_SCREEN_LEN
        mov     ax,data
        mov     ds,ax
        mov     ax,0xbb80                       ;buffer for page 7
        mov     es,ax

        mov     si,help_screen                  ;ds:si -> help_screen
        sub     di,di                           ;es:di -> video

.loop:
        lodsb
        stosb
        inc     di                              ;es:di++ (skip attrib byte)
        loop    .loop

        pop     es
        pop     ds

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data data

help_screen:
           ;0123456789+123456789+123456789+123456789
        db 'PCjr diagnostic tests              - riq'
        db '                                        '
        db 'Choose a test:                          '
        db '                                        '
        db 'Floppy:    0, 1, 2, 3                   '
        db 'Video:     4, 8, 5                      '
        db 'Sound:     9                            '
        db 'Keyboard:  j, k                         '
        db 'Modem:     g                            '
        db 'P Printer: a, b, c, d                   '
        db 'S Printer: h                            '
        db 'RS232:     i                            '
        db 'Joystick:  6, 7, e                      '
        db '                                        '
        db 'Special values:                         '
        db '           x = 0x00                     '
        db '           y = 0x01                     '
        db '           z = 0xff                     '
HELP_SCREEN_LEN equ $ - help_screen

xlat_table:


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 2048
stacktop:
