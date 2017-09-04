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
        call    wait_key

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

        call    do_scroll

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
        mov     ah,222                          ;char
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
do_scroll:
        mov     ax,0xb800                       ;init some variables to be used
        mov     es,ax                           ; during the scroll
        cld                                     ;fordward copy for the scroll

.l0:
        call    wait_vert_retrace
        call    anim_palette
        call    set_initial_pixels
        call    scroll_pixels

        jmp .l0
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
anim_palette:
        int     3
;        dec     byte [palette_delay]
;        jz      .anim
;        ret
;
;.anim
;        mov     byte [palette_delay],16

        sub     bh,bh
        mov     ax,palette_data
        mov     bl,[palette_idx]
        and     bl,0x07
        add     ax,bx
        inc     byte [palette_idx]

        mov     si,ax

        mov     bl,0x10                         ;palette register
        mov     cx,0x10                         ;number of colors
        mov     dx,0x3da

.repeat:
        mov     al,bl
        out     dx,al                           ;select palette register

        add     dx,4
        lodsb
        add     si,7                            ;each color has 8 entries. go to the next one
        out     dx,al                           ;palette color

        inc     bl
        sub     dx,4

        loop    .repeat

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
scroll_pixels:
        push    ds

        push    es
        pop     ds

        %assign i 0
        %rep    8

                mov     cx,79                   ;scroll 1 line of 80 chars
                mov     si,(92+i)*160+2         ;source: last char of screen
                mov     di,(92+i)*160           ;dest: last char of screen - 1

                rep movsw                       ;do the copy

        %assign i i+1
        %endrep

        pop     ds
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
set_initial_pixels:
        mov     bx,[char_idx]                   ;get char index
        mov     al,[scroll_text + bx]           ;get char to print
        or      al,al                           ;al is 0? (end of scroll text)
        jne     .l0

        sub     ax,ax
        mov     [char_idx],ax
        mov     al,[scroll_text]

.l0:
        sub     bx,bx
        mov     bl,al                           ;move char to bx
        shl     bx,1                            ;bx *= 8. since each char takes
        shl     bx,1                            ; 8 bytes.
        shl     bx,1

        mov     cx,8                            ;do this 8 times: one per pixel

.repeat:
        mov     al,[charset + bx]               ;get charset definition of char.
                                                ; bx will get increased by one
                                                ; in each loop
        sub     dx,dx
        mov     si,[pixel_idx]                  ;si goes from 0-3

        push    bx                              ;reusing bx for base indexed

        mov     bx,cx

        test    al,[pixel_patterns_even+si]
        jz      .l1
        or      dl,[colors_even+si+bx]          ;color for when "even" pixel is on

.l1:
        test    al,[pixel_patterns_odd+si]
        jz      .l2
        or      dl,[colors_odd+si+bx]           ;color for when "odd" pixel is on

.l2:
        mov     bx,cx                           ;get next address
        dec     bx                              ;minus 1, since cx starts at 8
        shl     bx,1                            ;points to correct next address
        mov     di,[pixel_addresses + bx]

        mov     byte [es:di],dl

        pop     bx                              ;restore bx. used for [chardef + bx]

        inc     bx                              ;pointer to next char def in charset

        loop    .repeat                         ;do it 8 times (8 pixels high)


        mov     ax,[pixel_idx]                  ;pixel_idx++
        inc     ax
        cmp     ax,4                            ;if pixel_idx == 4, reset pixel_idx
        jne     .end

        sub     ax,ax                           ;reset pixel_idx and
        inc     word [char_idx]                 ; ind char_idx

.end:
        mov     [pixel_idx],ax

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

crt6845_3d4_160_100:
        ;     0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
        db 0x71, 0x50, 0x5a, 0x0a, 0x7f, 0x06, 0x64, 0x70, 0x02, 0x01, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00       ; 160x100

image:
       incbin "image160100.bin"

charset:
        ;incbin "tandy_1000_hx_charset-charset.bin"
        incbin "c64_charset-charset.bin"

scroll_text:
        db 'esto es una prueba de scroll, veremos que pasa... esto compila...'
        db 'ojala que si... funciona, yo que se, la vida es jodida... probando'
        db ' MAYUSCULAS, minusculas, y otras cosas raras... 0123456789 !@#$!@#$%^&&'
        db '       CHAU ......    '
        db 0
char_idx:
        dw 0                                    ;pointer to the next char to be
                                                ; used for the scroll
pixel_idx:
        dw 0                                    ;pointer to the next pixel to be
                                                ; used for the scroll. belongs
                                                ; to the char

pixel_patterns_even:                            ;mask for the charset char. these
        db 0b1000_0000                          ; are the "even" values for the mask
        db 0b0010_0000
        db 0b0000_1000
        db 0b0000_0010

pixel_patterns_odd:                             ;mask for the charset char. these
        db 0b0100_0000                          ; are the "odd" values for the mask
        db 0b0001_0000
        db 0b0000_0100
        db 0b0000_0001

pixel_addresses:                                ;addresses for the right-most
        dw 100*160-1                            ; column for the 8 pixels. they
        dw  99*160-1                            ; are inverted since it uses cx
        dw  98*160-1                            ; as the indexer
        dw  97*160-1
        dw  96*160-1
        dw  95*160-1
        dw  94*160-1
        dw  93*160-1

colors_even:                                    ;colors are indexed by [row+col]
        db 0x40,0x40,0x40,0x50                  ; row goes from 0-7
        db 0x50,0x50,0xc0,0xc0                  ; col goes from 0-3
        db 0xc0,0xe0,0xe0,0xe0

colors_odd:                                     ;colros are indexed by [row+col]
        db 0x04,0x04,0x04,0x05                  ; row goes from 0-7
        db 0x05,0x05,0x0c,0x0c                  ; col goes from 0-3
        db 0x0c,0x0e,0x0e,0x0e

palette_data:                                   ;each color has its own palette values
        db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00      ; each color has 8 possible values
        db 0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01
        db 0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02
        db 0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03
        db 0x04,0x04,0x05,0x05,0x0c,0x0c,0x0e,0x0e
        db 0x05,0x05,0x0c,0x0c,0x0e,0x0e,0x04,0x04
        db 0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06
        db 0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x07
        db 0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08
        db 0x09,0x09,0x09,0x09,0x09,0x09,0x09,0x09
        db 0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a
        db 0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b,0x0b
        db 0x0c,0x0c,0x0e,0x0e,0x04,0x04,0x05,0x05
        db 0x0d,0x0d,0x0d,0x0d,0x0d,0x0d,0x0d,0x0d
        db 0x0e,0x0e,0x04,0x04,0x05,0x05,0x0c,0x0c
        db 0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f
palette_idx:
        db 0
palette_delay:
        db 1
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
