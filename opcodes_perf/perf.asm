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

        mov     ax,0002                         ;80x25 text mode
        int     0x10

        call    start_tests
        call    wait_key

        mov     ax,0x4c00
        int     0x21                            ;exit to DOS


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_key:
        xor     ah,ah                           ;Function number: get key
        int     0x16                            ;Call BIOS keyboard interrupt
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
print_txt:
        push    dx
        mov     dx,txt_enter
        mov     ah,9
        int     0x21

        pop     dx
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
start_tests:
        ; nop
        mov     dx,txt_nop
        call    print_txt
        call    ZTimerOn

        times   1000 nop
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key


        ; aaa
        mov     dx,txt_aaa
        call    print_txt
        call    ZTimerOn

        times   1000 aaa
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; aad
        mov     dx,txt_aad
        call    print_txt
        call    ZTimerOn

        times   1000 aad
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; aam
        mov     dx,txt_aam
        call    print_txt
        call    ZTimerOn

        times   1000 aam
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key


        ; mov al,al
        mov     dx,txt_mov_al_al
        call    print_txt
        call    ZTimerOn

        times   1000 mov al,al
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; sub al,al
        mov     dx,txt_sub_al_al
        call    print_txt
        call    ZTimerOn

        times   1000 sub al,al
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; sub al,0
        mov     dx,txt_sub_al_0
        call    print_txt
        call    ZTimerOn

        times   1000 sub al,0
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; sub ax,0
        mov     dx,txt_sub_ax_0
        call    print_txt
        call    ZTimerOn

        times   1000 sub ax,0
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; xchg_cx_dx
        mov     dx,txt_xchg_cx_dx
        call    print_txt
        call    ZTimerOn

        times   1000 xchg cx,dx
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; xchg_ax_dx
        mov     dx,txt_xchg_ax_dx
        call    print_txt
        call    ZTimerOn

        times   1000 xchg ax,dx
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; inc al
        mov     dx,txt_inc_al
        call    print_txt
        call    ZTimerOn

        times   1000 inc al
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; inc ax
        mov     dx,txt_inc_ax
        call    print_txt
        call    ZTimerOn

        times   1000 inc ax
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; cwd
        mov     dx,txt_cwd
        call    print_txt
        call    ZTimerOn

        times   1000 cwd
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; in al,0x60
        mov     dx,txt_in_al_60
        call    print_txt
        call    ZTimerOn

        times   1000 in al,0x60
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; in al,dx
        mov     dx,txt_in_al_dx
        call    print_txt
        call    ZTimerOn

        times   1000 in al,dx
        
        call    ZTimerOff
        call    ZTimerReport
        call    wait_key


        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data

txt_enter:      db 13,10,'$'
txt_nop:
        db      'Testing: nop$'

txt_aaa:
        db      'Testing: aaa$'

txt_aad:
        db      'Testing: aad$'

txt_aam:
        db      'Testing: aam$'

txt_mov_al_al:
        db      'Testing: mov al,al$'

txt_sub_al_al:
        db      'Testing: sub al,al$'

txt_xchg_cx_dx:
        db      'Testing: xchg cx,dx$'

txt_xchg_ax_dx:
        db      'Testing: xchg ax,dx$'

txt_inc_al:
        db      'Testing: inc al$'

txt_inc_ax:
        db      'Testing: inc ax$'

txt_sub_ax_0:
        db      'Testing: sub ax,0$'

txt_sub_al_0:
        db      'Testing: sub al,0$'

txt_cwd:
        db      'Testing: cwd$'

txt_in_al_60:
        db      'Testing: in al,0x60$'

txt_in_al_dx:
        db      'Testing: in al,dx$'

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
