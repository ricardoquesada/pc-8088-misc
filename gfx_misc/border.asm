; border test
; riq/pvm

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

        mov     cx,262 * 60 * 3                 ;wait 3 seconds (262 * 60 * 3)
.repeat:
        call    anim_border_color

        loop    .repeat

        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
init_screen:
        mov     ax,0x0009                       ;320x200 16 colors
        int     0x10

        call    set_charset

        call    update_palette


        mov     cx,C64_SCREEN_SIZE
        mov     si,c64_screen

        mov     dx,0x0000                       ;row=0, column=0


.repeat:
        mov     ah,2                            ;set cursor position
        mov     bh,0                            ;page 0 (ignored in gfx mode though)
        int     0x10

        lodsb                                   ;char to write
        cmp     al,0                            ;anim char
        je      .do_anim_cursor
        cmp     al,1
        je      .do_delay
        cmp     al,`\n`
        je      .do_enter
        cmp     al,2
        je      .do_enable_user_input
        cmp     al,3
        je      .do_disable_user_input

        mov     ah,0x0a                         ;write char
        mov     bh,0                            ;page to write to
        mov     bl,9                            ;color: light blue

        push    dx
        push    cx

        mov     cx,1                            ;number of times to write to
        int     0x10

        mov     al,[delay_after_char]
        cmp     al,1
        jne     .l1
        call    wait_vert_retrace

.l1:
        pop     cx
        pop     dx

        inc     dl                              ;cursor.x +=1


.l0:
        loop    .repeat

        ret

.do_anim_cursor:
        call    do_anim_cursor
        jmp     .l0

.do_delay:
        push    cx
        mov     cx,60
        call    do_delay
        pop     cx
        jmp     .l0

.do_enter:
        int     3
        inc     dh                              ;inc row
        mov     dl,0                            ;reset column
        jmp     .l0

.do_enable_user_input:
        mov     byte [delay_after_char],1
        jmp     .l0

.do_disable_user_input:
        mov     byte [delay_after_char],0
        jmp     .l0

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
do_anim_cursor:
        push    cx
        push    dx

        mov     cx,4
.repeat:
        push    cx
        mov     al,219                          ;block char
        mov     ah,0x0a                         ;write char
        mov     bh,0                            ;page to write to
        mov     bl,9                            ;color: light blue
        mov     cx,1                            ;only once
        int     0x10                            ;write char
        pop     cx

        push    cx
        mov     cx,20
        call    do_delay
        pop     cx

        push    cx
        mov     al,32                           ;empty char
        mov     ah,0x0a                         ;write char
        mov     bh,0                            ;page to write to
        mov     bl,9                            ;color: light blue
        mov     cx,1                            ;only once
        int     0x10                            ;write char
        pop     cx

        push    cx
        mov     cx,20
        call    do_delay
        pop     cx

        loop    .repeat

        pop     dx
        pop     cx

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; On entry:
;       cx:     number of vertical retraces to wait
do_delay:
        push    dx
.repeat:
        call    wait_vert_retrace
        loop    .repeat
        pop     dx

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
        mov     dx,0x3da

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

delay_after_char:
        db 0

c64_screen:
           ;0123456789012345678901234567890123456789
        db `\n`
        db `    **** COMMODORE 64 BASIC V2 ****\n`
        db ` 64K RAM SYSTEM  38911 BASIC BYTES FREE\n`
        db `\n`
        db `READY.\n`
        db 0                                            ; pause / animate cursor
        db 2                                            ;turn on user input
        db `LOAD"$",8\n\n`
        db 3                                            ;turn off user input
        db 1                                            ; pause / animate cursor
        db `SEARCHING FOR $\n`
        db 1                                            ; pause
        db `LOADING\n`
        db 1
        db `READY.\n`
        db 0                                            ; pause / animate cursor
        db 2                                            ;turn on user input
        db `LIST\n\n`
        db 3                                            ;turn off user input
        db '0 '
        db 162,208,214,205,160,195,182,180,207,205,193,199,197,160,160,160,160,162         ;inverted chars
        db 160,185,182,160,178,193
        db `\n`
        db `132  "C64OMAGE"         PRG\n`
        db `532 BLOCKS FREE.\n`
        db `READY.\n`
        db 0                                            ; pause / animate cursor
        db 2                                            ;turn on user input
        db `LOAD"*",8,1\n\n`
        db 3                                            ;turn off user input
        db `SEARCHING FOR *\n`
        db 1
        db `LOADING`,1,1,1,1,1
        db `               (10 minutes later)\n`
        db 1,1
        db `READY.\n`
        db 0
        db 2                                            ;turn on user input
        db `RUN\n`
        db 3                                            ;turn off user input
C64_SCREEN_SIZE equ $ - c64_screen


c64_charset:
        incbin 'c64_charset-charset.bin'
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
