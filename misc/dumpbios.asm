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
        call    save_file_f000                  ;Save BIOS f000-7FFF
        call    save_file_f800                  ;Save BIOS f800-FFFF

        mov     ax,0x4c00                       ;exit to DOS
        int     0x21

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

filename_f000:
        db      'BIOSF000.BIN', 0
filename_f800:
        db      'BIOSF800.BIN', 0
error_msg:
        db      'error writing file', '$'


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
