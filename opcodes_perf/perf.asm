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
extern detect_card

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

        mov     ax,0000                         ;40x25 text mode
        int     0x10

        call    detect_card
        mov     [video_card],al
        call    print_detected_card

        call    start_tests
        sti

        mov     ax,0x4c00
        int     0x21                            ;exit to DOS


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
print_detected_card:
        sub     ah,ah
        mov     al,byte [video_card]
        shl     al,1
        mov     bx,ax
        mov     dx,[video_card_tbl+bx]
        mov     ah,9
        int     0x21
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
global start_tests
start_tests:
        cli

        call    disable_interrupts

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

        ; mov dx,0
        mov     dx,txt_mov_dx_0
        call    print_txt
        call    ZTimerOn

        times   1000 mov dx,0

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; mov dl,0
        mov     dx,txt_mov_dl_0
        call    print_txt
        call    ZTimerOn

        times   1000 mov dl,0

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

        ; push dx
        mov     dx,txt_push_dx
        call    print_txt
        call    ZTimerOn

        times   1000 push dx

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; pop dx
        mov     dx,txt_pop_dx
        call    print_txt
        call    ZTimerOn

        times   1000 pop dx

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key


        ; mov ax, word [0000]
        mov     dx,txt_mov_ax_off_0000
        call    print_txt
        call    ZTimerOn

        times   1000 mov ax, word [0000]

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; mov al, byte [0000]
        mov     dx,txt_mov_al_off_0000
        call    print_txt
        call    ZTimerOn

        times   1000 mov al, byte [0000]

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; out dx, al
        mov     dx,txt_out_dx_al
        call    print_txt
        mov     dx,0x0                  ; out port
        call    ZTimerOn

        times   1000 out dx, al

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; mul al
        mov     dx,txt_mul_al
        call    print_txt
        call    ZTimerOn

        times   1000 mul al

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; mul ax
        mov     dx,txt_mul_ax
        call    print_txt
        call    ZTimerOn

        times   1000 mul ax

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; div bl
        mov     dx,txt_div_bl
        call    print_txt
        mov     ax,1
        mov     bl,1                    ; div by 1
        call    ZTimerOn

        times   1000 div bl

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; div bx
        mov     dx,txt_div_bx
        call    print_txt
        mov     ax,1
        mov     dx,0
        mov     bx,1                    ; div by 1
        call    ZTimerOn

        times   1000 div bx

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; xlat
        mov     dx,txt_xlat
        call    print_txt
        mov     bx,0                    ; xlat table
        call    ZTimerOn

        times   1000 xlat

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; rep movsb
        mov     dx,txt_rep_movsb
        call    print_txt

        mov     cx,1000
        mov     si,0
        mov     di,0
        push    ds
        pop     es                      ;src = dst

        call    ZTimerOn

        rep     movsb

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key


        ; rep movsw
        mov     dx,txt_rep_movsw
        call    print_txt

        mov     cx,1000
        mov     si,0
        mov     di,0
        push    ds
        pop     es                      ;src = dst

        call    ZTimerOn

        rep     movsw

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key


        ; shl al,1
        mov     dx,txt_shl_al_1
        call    print_txt
        call    ZTimerOn

        times   1000 shl al,1

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; shl al,cl
        mov     dx,txt_shl_al_cl
        call    print_txt
        mov     cl,4
        call    ZTimerOn

        times   1000 shl al,cl

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; loop
        mov     dx,txt_loop
        call    print_txt
        mov     cx,1000
        call    ZTimerOn

l0:
        loop    l0

        call    ZTimerOff
        call    ZTimerReport
        call    wait_key

        ; re-enable pic
        call    enable_interrupts

        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
disable_interrupts:
        cli

        in      al,0x21                         ;Read primary PIC Interrupt Mask Register
        mov     [old_pic_imr],al                ;Store it for later
        mov     al,0b1111_1110                  ;Mask off everything
        out     0x21,al

        call    disable_nmi
        ret

disable_nmi:
        cmp     byte [video_card],2             ;pcjr is two
        jnz     .exit
        mov     al,0                            ;PCjr only: disable nmi
        out     0xa0,al
.exit
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
enable_interrupts:
        mov     al,[old_pic_imr]
        out     0x21,al

        call    enable_nmi
        sti

        ret

enable_nmi:
        ; It is important to disable NMI on PCjr because the NMI on the PCjr
        ; is triggered by the IR Keyboard code. By disabling it, we will have
        ; more stable values.
        ; In theory, it should be "safe" to disable NMI in all platforms (PC, PCjr,
        ; and Tandy 1000). But on the Tandy, the first 3 bits of 0xa0 are used to
        ; configure the memory and changing them might crash the computer if not
        ; used correctly.
        cmp     byte [video_card],2
        jnz     .exit
        in      al,0xa0
        mov     al,0b1000_0000                  ;PCjr only: enable nmi
        out     0xa0,al
.exit:
        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_key:
        ;enable keyboard interrupt
        call    enable_interrupts

        xor     ah,ah                           ;Function number: get key
        int     0x16                            ;Call BIOS keyboard interrupt

        call    disable_interrupts

        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data

old_pic_imr:    db 0

video_card:     db 0
video_card_mda:          db 'MDA',13,10,'$'
video_card_cga:          db 'CGA', 13,10,'$'
video_card_pcJr:         db 'PCjr', 13,10,'$'
video_card_tandy1000:    db 'Tandy1000',13,10,'$'
video_card_tandySLTL:    db 'Tandy1000 sl/tl',13,10,'$'
video_card_ega:          db 'EGA',13,10,'$'
video_card_vga:          db 'VGA',13,10,'$'
video_card_mcga:         db 'MCGA',13,10,'$'

video_card_tbl:
        dw      video_card_mda
        dw      video_card_cga
        dw      video_card_pcJr
        dw      video_card_tandy1000
        dw      video_card_tandySLTL
        dw      video_card_ega
        dw      video_card_vga
        dw      video_card_mcga

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

txt_mov_dx_0:
        db      'Testing: mov dx,0$'

txt_mov_dl_0:
        db      'Testing: mov dl,0$'

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

txt_push_dx:
        db      'Testing: push dx$'

txt_pop_dx:
        db      'Testing: pop dx$'

txt_mov_ax_off_0000:
        db      'Testing: mov ax, word [0000]$'

txt_mov_al_off_0000:
        db      'Testing: mov al, byte [0000]$'

txt_out_dx_al:
        db      'Testing: out dx, ax$'

txt_mul_al:
        db      'Testing: mul al$'

txt_mul_ax:
        db      'Testing: mul ax$'

txt_div_bl:
        db      'Testing: div bl$'

txt_div_bx:
        db      'Testing: div bx$'

txt_xlat:
        db      'Testing: xlat$'

txt_rep_movsb:
        db      'Testing: rep movsb$'

txt_rep_movsw:
        db      'Testing: rep movsw$'

txt_shl_al_1:
        db      'Testing: shl al,1$'

txt_shl_al_cl:
        db      'Testing: shl al,cl / cl=4$'

txt_loop:
        db      'Testing: loop$'

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
