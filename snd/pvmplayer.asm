; PVM (Play VGM Music) player
; Author: riq/pvm
;
; PIC & IRQ init code: taken from tandysnd.asm by bisqwit@
; PIC & IRQ fixes: by trixter@

bits    16
cpu     8086

; Timing settings:
PIT_divider     equ (262*76)                    ;262 lines * 76 cycles each
                                                ; (14318180 / 12) / 19912 = 59.9227 Hz

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

        call    wait_key

        call    music_init                      ;must be called before setup_irq
        call    setup_irq

        call    player_main

        call    restore_irq
        call    sound_cleanup

        mov     ax,4C00h                        ;Terminate program
        int     21h                             ;INT 21, AH=4Ch, AL=exit code

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Parametros
; Chequea que los parametros de la linea sean correctos
; ES:0081 -> empieza.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
parse_cmd_line:
        push ds
        push es

        push    ds                              ;swap ds,es
        pop     es
        pop     ds
        pop     es

        cld
        mov     di,filename                     ;location for name
        mov     si,81h                          ;params are in ds:si

.loop:
        lodsb                                   ;al <- ds:si ( si++)
        cmp     al,20h                          ;space?
        je      .loop                           ;keep reading if it is space
        cmp     al,13                           ;return?
        je      .exit                           ;if so, exit

                                                ;otherwise it is the filename to read
        stosb                                   ;write name in es:di
        jmp     .loop                           ; and keep reading

.exit:
        mov     al,0
        stosb                                   ;es:di -> 0 (asciiz)
        mov     al,'$'                          ;to show filename
        stosb

        pop  es
        pop  ds
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
setup_irq:
        cli

        push    ds
        xor     ax,ax
        mov     ds,ax

        mov     ax,new_i08
        mov     dx,cs
        xchg    ax,[ds:8*4]
        xchg    dx,[ds:8*4+2]
        mov     [cs:old_i08],ax
        mov     [cs:old_i08+2],dx

        pop     ds

        mov     ax,PIT_divider                  ;Configure the PIT to
        call    setup_PIT                       ;issue IRQ at 60 Hz rate

        in      al,21h                          ;Read primary PIC IMR
        mov     [PIC0IMR],al                    ;Store it for later
        mov     al,11111100b                    ;Mask off everything except IRQ 0
        out     21h,al                          ; and IRQ1 (timer and keyboard)

        sti
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
restore_irq:
        cli

        mov     al,[PIC0IMR]                    ;Get old PIC settings
        out     21h,al                          ;Set primary PIC IMR

        mov     ax,0                            ;Reset PIT to defaults (~18.2 Hz)
        call    setup_PIT                       ; actually means 10000h

        push    ds
        xor     ax,ax
        mov     ds,ax
        les     si,[cs:old_i08]
        mov     [ds:8*4],si
        mov     [ds:8*4+2],es                   ;Restore the old INT 08 vector
        pop     ds

        sti
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
music_init:
        mov     word [pvm_offset],pvm_song + 0x10       ;update start offset
        mov     byte [pvm_wait],0               ;don't wait at start
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
player_main:

        ; Main loop
.mainloop:
        hlt                                     ;wait for IRQ

.l2:
        ; Loop until some input is given
        mov     ah,1
        int     16h                             ;INT 16,AH=1, OUT:ZF=status
        jz      .mainloop

        ; Read the input key
        xor     ax,ax
        int     16h                             ;INT 16,AH=0, OUT:AX=key
        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
wait_key:
        xor     ah,ah                           ;Function number: get key
        int     0x16                            ;Call BIOS keyboard interrupt
        ret

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
sound_cleanup:
        ; FIXME: do the cleanup
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
song_tick:

DATA    equ     0b0000_0000
DATA_EXTRA equ  0b0010_0000
DELAY   equ     0b0100_0000
DELAY_EXTRA equ 0b0110_0000
END     equ     0b1000_0000

        int     3
        push    ax
        push    cx
        push    si
        push    ds

        mov     ax,data
        mov     ds,ax

        sub     cx,cx                           ;cx=0... needed later
        mov     si,[pvm_offset]

        cmp     byte [pvm_wait],0
        je      .l0

        dec     byte [pvm_wait]
        jmp     .exit

.l0:
        lodsb                                   ;fetch command byte
        mov     ah,al
        and     al,0b1110_0000                  ;al=command only
        and     ah,0b0001_1111                  ;ah=command args only

        cmp     al,DATA                         ;data?
        je      .is_data
        cmp     al,DATA_EXTRA                   ;data extra?
        je      .is_data_extra
        cmp     al,DELAY                        ;delay?
        je      .is_delay
        cmp     al,DELAY_EXTRA                  ;delay extra?
        je      .is_delay_extra
        cmp     al,END                          ;end?
        je      .is_end

.unsupported:
        int     3
        jmp     .exit


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.is_data:
        mov     cl,ah                           ;ch is already zero
        jmp     .repeat

.is_data_extra:
        lodsb                                   ;fetch lenght from next byte
        mov     cl,al
.repeat:
        lodsb
        out     0xc0,al
        loop    .repeat

        jmp     .l0                             ; repeat... fetch next command


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.is_delay:
        dec     ah                              ;minus one, since we are returning
        mov     [pvm_wait],ah                   ; from here now
        jmp     .exit

.is_delay_extra:
        lodsb                                   ;fetch wait from next byte
        dec     al                              ;minus one, since we are returning
        mov     [pvm_wait],al                   ; from here now
        jmp     .exit

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.is_end:
        mov     byte [pvm_wait], 5              ;wait 5 cycles before starting again
        mov     word [pvm_offset], pvm_song + 0x10      ; beginning of song
        jmp     .exit_skip

.exit:
        mov     [pvm_offset],si
.exit_skip:

        pop     ds
        pop     si
        pop     cx
        pop     ax
        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; IRQ
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
new_i08:; New INT 08 (timer IRQ) handler

        call    song_tick

        add     word [cs:i08_counter],PIT_divider
        jnc     skip_old_i08
        db      0EAh                            ;Jump far
old_i08:        dd 0                            ;Old INT 08 vector
skip_old_i08:

        push    ax
        mov     al,20h                          ;Send the EOI signal
        out     20h,al                          ;to the IRQ controller
        pop     ax

        iret                                    ;Exit interrupt

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

filename:
        resb    64                              ; 64 bytes for the name

pvm_song:
;        incbin "music_test.pvm"
;        incbin "anime.pvm"
        incbin "short-lived.pvm"

pvm_wait:                                       ;cycles to read diviced 0x2df
        db 0
pvm_offset:                                     ;pointer to next byte to read
        dw 0

PIC0IMR:
        db 0                                    ;PICOIMR original value

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; section STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb 4096
stacktop:
