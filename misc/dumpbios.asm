; Dumps BIOS in two files
;
bits    16
cpu     8086

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
        call    save_file_zero                  ;Save 0000-03ff
;        call    save_file_e000                  ;Save BIOS e000-7FFF
;        call    save_file_e800                  ;Save BIOS e800-FFFF
;        call    save_file_f000                  ;Save BIOS f000-7FFF
;        call    save_file_f800                  ;Save BIOS f800-FFFF

        mov     ax,0x4c00                       ;exit to DOS
        int     0x21

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
save_file_zero:
        push    ds
        push    es

        xor     si,si,
        mov     ds,si                           ;ds:si = 0000:0000

        mov     ax,seg tmp_int_vector
        mov     es,ax
        mov     di,tmp_int_vector               ;es:di = ds:tmp_int_vector

        mov     cx,2048

        cld
        rep movsw

        push    es 
        pop     ds

        mov     ax,0x3c00                       ;create file
        mov     dx,filename_zero
        mov     cx,0                            ;attributes
        int     0x21
        jc      .error

        mov     bx,ax                           ;file handle
        mov     cx,0x0400                       ;1k bytes to write

        mov     dx,tmp_int_vector               ;ds:dx buffer to save

        mov     ax,0x4000                       ;write file
        int     0x21
        jc      .error

        mov     ax,0x3e00                       ;close fd
        int     0x21
        jc      .error

        pop     es
        pop     ds
        ret

.error:
        pop     es
        pop     ds
        mov     dx,error_msg
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
save_file_e000:
        push    ds

        mov     ax,0x3c00                       ;create file
        mov     dx,filename_e000
        mov     cx,0                            ;attributes
        int     0x21
        jc      .error

        mov     bx,ax                           ;file handle
        mov     cx,0x8000                       ;32k bytes to write

        sub     dx,dx                           ;buffer DS:DX e000:0000
        mov     ax,0xe000
        mov     ds,ax

        mov     ax,0x4000                       ;write file
        int     0x21
        jc      .error

        mov     ax,0x3e00                       ;close fd
        int     0x21
        jc      .error

        pop     ds
        ret

.error:
        pop     ds
        mov     dx,error_msg
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
save_file_e800:
        push    ds

        mov     ax,0x3c00                       ;create file
        mov     dx,filename_e800
        mov     cx,0                            ;attributes
        int     0x21
        jc      .error

        mov     bx,ax                           ;file handle
        mov     cx,0x8000                       ;bytes to write

        sub     dx,dx                           ;buffer DS:DX e800:0000
        mov     ax,0xe800
        mov     ds,ax

        mov     ax,0x4000                       ;write file
        int     0x21
        jc      .error

        mov     ax,0x3e00                       ;close fd
        int     0x21
        jc      .error

        pop     ds
        ret

.error:
        pop     ds
        mov     dx,error_msg
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
save_file_f000:
        push    ds

        mov     ax,0x3c00                       ;create file
        mov     dx,filename_f000
        mov     cx,0                            ;attributes
        int     0x21
        jc      .error

        mov     bx,ax                           ;file handle
        mov     cx,0x8000                       ;32k bytes to write

        sub     dx,dx                           ;buffer DS:DX f000:0000
        mov     ax,0xf000
        mov     ds,ax

        mov     ax,0x4000                       ;write file
        int     0x21
        jc      .error

        mov     ax,0x3e00                       ;close fd
        int     0x21
        jc      .error

        pop     ds
        ret

.error:
        pop     ds
        mov     dx,error_msg
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
save_file_f800:
        push    ds

        mov     ax,0x3c00                       ;create file
        mov     dx,filename_f800
        mov     cx,0                            ;attributes
        int     0x21
        jc      .error

        mov     bx,ax                           ;file handle
        mov     cx,0x8000                       ;bytes to write

        sub     dx,dx                           ;buffer DS:DX f800:0000
        mov     ax,0xf800
        mov     ds,ax

        mov     ax,0x4000                       ;write file
        int     0x21
        jc      .error

        mov     ax,0x3e00                       ;close fd
        int     0x21
        jc      .error

        pop     ds
        ret

.error:
        pop     ds
        mov     dx,error_msg
        mov     ah,9
        int     0x21
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

filename_zero:
        db      'ZEROPAGE.BIN', 0
filename_f000:
        db      'BIOSF000.BIN', 0
filename_f800:
        db      'BIOSF800.BIN', 0
filename_e000:
        db      'BIOSE000.BIN', 0
filename_e800:
        db      'BIOSE800.BIN', 0
error_msg:
        db      'error writing file', '$'

tmp_int_vector:
        resb 4096


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
