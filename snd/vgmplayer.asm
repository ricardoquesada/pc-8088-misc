; Very simple VGM Player for Tandy 1000
; Only supports VGM v1.50, only output is SN76489, and only Freq is NTSC
;
; riq/pvm

bits    16
cpu     8086

; Timing settings:
IRQ_rate        equ 60
PIT_divider     equ 19886                       ; 1234DCh / IRQ_rate

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; CODE
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .text code
..start:

main:
        mov     ax,data                         ;init segments
        mov     ds,ax                           ; DS=ES: same segment
        mov     es,ax                           ; SS: stack
        mov     ax,stack
        cli                                     ;disable interrupts while
        mov     ss,ax                           ; setting the stack pointer
        mov     sp,stacktop
        sti

        ; Load the old INT 08 vector
        ; and install our own

        push    ds
        sub     ax,ax
        mov     ds,ax

        cli
        mov     ax,new_i08
        mov     dx,cs
        xchg    ax,[ds:8*4]
        xchg    dx,[ds:8*4+2]
        mov     [cs:old_i08],ax
        mov     [cs:old_i08+2],dx

        pop     ds

        ; Configure the PIT to
        ; issue IRQ at 60 Hz rate
        mov     ax,PIT_divider
        call    setup_PIT
        sti

        call    wait_key
        call    player_main

        cli
        ; Reset PIT to defaults (~18.2 Hz)
        mov    ax,0                             ;actually means 10000h
        call   setup_PIT

         ; Restore the old INT 08 vector
        xor     ax,ax
        mov     ds,ax
        les     si,[cs:old_i08]
        mov     [ds:8*4],si
        mov     [ds:8*4 + 2],es
        sti

        ; Terminate program
        mov     ax,4C00h
        int     21h                             ; INT 21, AH=4Ch, AL=exit code

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
player_main:
        mov     word [vgm_offset],vgm_song + 0x40       ;update start offset
        mov     ax,[vgm_song + 4]               ;update end offset
        add     ax,4
        mov     word [vgm_end],ax

        ; Main loop
.mainloop:
        hlt ; wait for IRQ
        ; Check it was timer IRQ
        mov     al,0
        xchg    al,[cs:IRQ_ticked]
        test    al,al
        jz      .l2
        ; It was; advance the song.
        call    song_tick

.l2:
        ; Loop until some input is given
        mov     ah, 1
        int     16h                             ; INT 16,AH=1, OUT:ZF=status
        jz      .mainloop

        ; Read the input key
        xor     ax, ax
        int     16h                             ; INT 16,AH=0, OUT:AX=key
        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_key:
        xor     ah,ah                           ;Function number: get key
        int     0x16                            ;Call BIOS keyboard interrupt
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; HARDWARE I/O ROUTINES
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;

setup_PIT:
        ; AX = PIT clock period
        ;          (Divider to 1193180 Hz)
        push    ax
        mov     al,34h
        out     43h,al
        pop     ax
        out     40h,al
        mov     al,ah
        out     40h,al
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
song_tick:

        mov     si,[vgm_offset]
        cmp     si,[vgm_end]
        jb      .ok

        int     3
        mov     ax,0x2df * 10                   ;wait 10 cycles and start from
        mov     word [vgm_offset], 0x40 + vgm_song      ; beginning of song
        ret

.ok:
        mov     ax,[vgm_wait]
        cmp     ax,0
        jz      .repeat

        sub     ax,0x2df                        ;one less cycle to wait
        mov     [vgm_wait],ax
        ret

.repeat:
        lodsb
        cmp     al,0x50
        je      .out_port
        cmp     al,0x62
        je      .wait_1_cycle
        cmp     al,0x61
        je      .wait_n_cycles
        cmp     al,0x66
        je      .end_sound_data

.unsupported:
        int     3
        mov     [vgm_offset],si                 ;save offset
        ret

.out_port:
        lodsb
        out     0xc0,al
        jmp     .repeat

.wait_1_cycle:
        mov     [vgm_offset],si
        ret

.wait_n_cycles:
        lodsw
        sub     ax,0x2df                        ;one less cycle to wait (this one)
        mov     [vgm_wait],ax

        mov     [vgm_offset],si                 ;save offset
        ret

.end_sound_data
        mov     ax,0x2df * 10                   ;wait 10 cycles and start from
        mov     word [vgm_offset], 0x40 + vgm_song      ; beginning of song

        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; IRQ
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
new_i08:; New INT 08 (timer IRQ) handler
        push    ax
        mov     byte [cs:IRQ_ticked],1
        add     word [cs:i08_counter],PIT_divider
        jnc     skip_old_i08
        pop     ax
        db      0EAh                            ; Jump far
old_i08:        dd 0                            ; Old INT 08 vector
skip_old_i08:
        mov     al,20h                          ; Send the EOI signal
        out     20h,al                          ; to the IRQ controller
        pop     ax
        iret                                    ; Exit interrupt

IRQ_ticked:     db 0
i08_counter:    dw 0
; I08counter makes it possible to call the
; the old IRQ vector at the right rate.
; At every INT, it is incremented by:
;       10000h * (oldrate/newrate)
; Which happens to evaluate into the same
; as PITdivider when the oldrate is the
; standard ~18.2 Hz. Whenever it overflows,
; it's time to call the old IRQ handler.
; This ensures that the old IRQ handler is
; called at the standard 18.2 Hz rate.

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; section DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data data

vgm_song:
;        incbin "music_test.vgm"
;        incbin "anime.vgm"
        incbin "short-lived.vgm"

vgm_wait:                                       ; cycles to read diviced 0x2df
        dw 0
vgm_offset:                                     ; pointer to next byte to read
        dw 0x40
vgm_end:                                        ; end of song offset
        dw 0

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; section STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
