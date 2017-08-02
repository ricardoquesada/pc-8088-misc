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
        int     3
        mov     ax, [gfx_modes+si]              ;get correct video mode for dx
        int     0x10                            ;switch video mode

        call    ZTimerOn
        call    load_file
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_retrace:

        mov     dx,0x3da
.l0:
        in      al,dx                           ;test for vertical retrace
        test    al,8
        jz      .l0

.l1:
        in      al,dx                           ;test for vertical retrace
        test    al,8                            ; to finish
        jnz     .l1
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
set_border_color:
        mov     dx,0x3da
        mov     al,2                            ;2=border color
        out     dx,al

        mov     dx,0x3de
        mov     al,1                            ;1=blue color
        out     dx,al
        rts

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
paint_screen:

        mov     cx,8000                         ;bank #0
        mov     al,0xee                         ;byte to 'paint'

        mov     bx,0xb800
        mov     es,bx
        xor     di,di                           ;es:di: destination
        rep stosb


        mov     cx,8000                         ;bank #1
        mov     al,0x12

        mov     bx,0xb800
        mov     es,bx
        mov     di,0x2000                       ;es:di: destination
        rep stosb


        mov     cx,8000                         ;bank #2
        mov     al,0x34

        mov     bx,0xb800
        mov     es,bx
        mov     di,0x4000                       ;es:di: destination
        rep stosb


        mov     cx,8000                         ;bank #3
        mov     al,0x56

        mov     bx,0xb800
        mov     es,bx
        mov     di,0x6000                       ;es:di: destination
        rep stosb
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
paint_ram:

        mov     cx,8000                         ;bank #0
        mov     al,0xee

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep stosb


        mov     cx,8000                         ;bank #1
        mov     al,0x12

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep stosb


        mov     cx,8000                         ;bank #2
        mov     al,0x34

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep stosb


        mov     cx,8000                         ;bank #3
        mov     al,0x56

        mov     bx,data
        mov     es,bx
        mov     di,0x8000                       ;es:di: destination
        rep stosb
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


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
