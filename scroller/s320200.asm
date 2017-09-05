; screoll test
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
        call    wait_key

        mov     ax,data                         ;init segments
        mov     ds,ax                           ; DS=ES: same segment
        mov     es,ax                           ; SS: stack
        mov     ax,stack
        cli                                     ;disable interrupts while
        mov     ss,ax                           ; setting the stack pointer
        mov     sp,stacktop
        sti

        call    init_screen

        call    paint_screen

        call    do_scroll

        call    wait_key

        mov     ax,0x0002                       ;text mode 80x25
        int     0x10

        mov     ax,0x4c00
        int     0x21                            ;exit to DOS

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
init_screen:
        mov     ax,0x0009                       ;320x200 16 colors
        int     0x10

        call    set_charset
        call    update_palette

        mov     ax,0xb800                       ;points to graphics memory
        mov     es,ax

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
paint_screen:

        mov     cx,1000

        mov     dx,0x0000                       ;row=0, column=0
        mov     al,0
.repeat:
        mov     ah,2                            ;set cursor position
        mov     bh,0                            ;page 0 (ignored in gfx mode though)
        int     0x10

        inc     dl
        cmp     dl,40
        jne     .l0

        sub     dl,dl
        inc     dh

.l0:
        push    cx

        mov     ah,0x0a                         ;write char
        mov     bh,0                            ;page to write to
        mov     bl,9                            ;color: light blue
        mov     cx,1                            ;number of times to write to
        int     0x10

        pop     cx

        inc     al

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
do_scroll:
        int     3

        push    ds

        push    es
        pop     ds

        cld

.repeat:
        call    wait_vert_retrace

        %assign i 0
        %rep    4

                mov     cx,159                  ;scroll 1 line of 80 chars
                mov     si,i*160+1            ;source: last char of screen
                mov     di,i*160              ;dest: last char of screen - 1
                rep movsb                       ;do the copy

                mov     cx,159                   ;scroll 1 line of 80 chars
                mov     si,8192+i*160+1            ;source: last char of screen
                mov     di,8192+i*160              ;dest: last char of screen - 1
                rep movsb                       ;do the copy

                mov     cx,159                   ;scroll 1 line of 80 chars
                mov     si,16384+i*160+1            ;source: last char of screen
                mov     di,16384+i*160              ;dest: last char of screen - 1
                rep movsb                       ;do the copy

                mov     cx,159                   ;scroll 1 line of 80 chars
                mov     si,24576+i*160+1            ;source: last char of screen
                mov     di,24576+i*160              ;dest: last char of screen - 1
                rep movsb                       ;do the copy

        %assign i i+1
        %endrep
        
        jmp     .repeat

        pop     ds

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

c64_charset:
        incbin 'c64_charset-charset.bin'

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
