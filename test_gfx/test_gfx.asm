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

        call    wait_key

        call    test_320_200_4                  ;call different tests
        call    test_640_200_2
        call    test_160_200_16
        call    test_320_200_16
        call    test_640_200_4

        mov     ax,0x0002                       ;text mode 80x25
        int     0x10

        mov     ax,0x4c00
        int     0x21                            ;exit to DOS


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

test_320_200_4:
        mov     si,0 * 2
        call    test_gfx
        ret

test_640_200_2:
        mov     si,1 * 2
        call    test_gfx
        ret

test_160_200_16:
        mov     si,2 * 2
        call    test_gfx
        ret

test_320_200_16:
        mov     si,3 * 2
        call    test_gfx
        ret

test_640_200_4:
        mov     si,4 * 2
        call    test_gfx
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
test_gfx:
        mov     ax, [gfx_modes+si]              ;get correct video mode for dx
        int     0x10                            ;switch video mode

        call    clear_video_mem

        call    ZTimerOn
        call    load_file
        call    ZTimerOff
        call    ZTimerReport

        call    wait_key
        call    scroll_up
        call    wait_key
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
scroll_up:
        mov     [crtc_start_addr], word 0
        mov     cx,[lines_per_screen+si]
.l0:
        call    wait_retrace
        call    inc_start_addr
        loop    .l0

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_retrace:

        mov     dx,0x3da
.l0:
        in      al,dx                           ;wait for vertical retrace
        test    al,8                            ; to start
        jz      .l0

.l1:
        in      al,dx                           ;wait for vertical retrace
        test    al,8                            ; to finish
        jnz     .l1
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
inc_start_addr:
        int     3
        mov     bx,[crtc_start_addr]
        add     bx,[chars_per_line+si]
        mov     [crtc_start_addr],bx

        mov     dx,0x3d4
        mov     al,0xc                          ;select CRTC start address hi
        out     dx,al

        inc     dx                              ;set value for CRTC lo address
        mov     al,bh
        out     dx,al

        dec     dx
        mov     al,0xd
        out     dx,al                           ;select CRTC start address lo

        inc     dx
        mov     al,bl
        out     dx,al                           ;set value for CRTC hi address

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
set_border_color:
        mov     dx,0x3da
        mov     al,2                            ;2=border color
        out     dx,al

        mov     dx,0x3de
        mov     al,1                            ;1=blue color
        out     dx,al

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
clear_video_mem:
        mov     cx,0x4000                       ;32k = 16k * 2

        mov     bx,0xb800
        mov     es,bx
        mov     di,0x0000                       ;es:di: destination
        sub     ax,ax
        rep stosw
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
load_file:
        push    ds

        mov     ah,0x3d                         ;open file
        mov     al,0
        mov     dx,[filenames+si]
        int     0x21
        jc      .error

        mov     bx,ax                           ;file handle
        mov     cx,[bytes_to_load+si]           ;bytes to read
        xor     dx,dx
        mov     ax,[gfx_buffer_addr+si]
        mov     ds,ax                           ;dst: ds:dx b800:0000
        mov     ah,0x3f                         ;read file
        int     0x21
        jc      .error

        mov     ah,0x3e                         ;close fd
        int     0x21
        jnc     .exit                           ;error? no, then exit
                                                ; else, falltrhought to error
.error:
        int     3
        mov     dx,error_msg
        mov     ah,9
        int     0x21
.exit:
        pop     ds
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

gfx_modes:
        dw 0x0004                               ;int 0x10 ah=0 gfx modes
        dw 0x0006
        dw 0x0008
        dw 0x0009
        dw 0x000a

gfx_buffer_addr:
        dw 0xb800
        dw 0xb800
        dw 0xb800
        dw 0xb800
        dw 0xb800

bytes_to_load:
        dw 16384                                ;bytes to load from file
        dw 16384
        dw 16384
        dw 32768
        dw 32768

chars_per_line:                                 ;for scrolling one line
        dw 40
        dw 40
        dw 40
        dw 80
        dw 80

lines_per_screen:                               ;for scrolling a full page
        dw 102
        dw 102
        dw 102
        dw 51
        dw 51

filenames:
        dw file_320_200_4                       ;filename to load
        dw file_640_200_2
        dw file_160_200_16
        dw file_320_200_16
        dw file_640_200_4

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

crtc_start_addr:
        dw      0
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
