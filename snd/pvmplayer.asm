; PVM (Play VGM Music) player
; Author: riq/pvm
;
; PIC & IRQ init code: taken from tandysnd.asm by @bisqwit
; PIC & IRQ fixes: by @trixter

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
        mov     ax,data                         ;init DS segment = data
        mov     ds,ax                           ;es should not be modified
        mov     ax,stack
        cli                                     ;disable interrupts while
        mov     ss,ax                           ; setting the stack pointer
        mov     sp,stacktop
        sti

        mov     dx,msg_title
        call    print_msg

        call    parse_cmd_line                  ;es must remain intact until this

        call    load_song

        call    music_init                      ;must be called before setup_irq
        call    setup_irq

        call    player_main

        call    restore_irq
        call    sound_cleanup

        mov     ax,4c00h                        ;Terminate program
        int     21h                             ;INT 21, AH=4Ch, AL=exit code

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
print_msg:
        mov     ah,9
        int     21h
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
parse_cmd_line:
        push ds
        push es

        push    ds                              ;swap ds,es
        push    es
        pop     ds
        pop     es

        cld                                     ;direction forward
        stc                                     ;carry on (means error)

        mov     di,filename                     ;location for name
        mov     si,81h                          ;params are in ds:si

.loop:
        lodsb                                   ;al <- ds:si ( si++)
        cmp     al,20h                          ;space?
        je      .loop                           ;keep reading if it is space
        cmp     al,13                           ;return?
        je      .exit                           ;if so, exit

        clc                                     ;clear carry. means an argument
                                                ; was passed
        stosb                                   ;write name in es:di
        jmp     .loop                           ; and keep reading

.exit:
        mov     al,0
        stosb                                   ;es:di -> 0 (asciiz)
        mov     al,'$'                          ;to show filename
        stosb

        pop     es
        pop     ds
        jc      .error
        ret

.error:
        mov     dx,msg_help
        call    print_msg
        mov     ax,4c01h
        int     21h


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
load_song:
        push    ds

        mov     dx,msg_loading
        call    print_msg
        mov     dx,filename
        call    print_msg
        mov     cx,msg_enter
        call    print_msg

        mov     ah,3dh                          ;open file
        mov     al,0
        mov     dx,filename
        int     21h
        jc      .error

        mov     bx,ax                           ;file handle
        mov     cx,0ffffh                       ;bytes to read: entire segment
        xor     dx,dx
        mov     ax,pvmsong
        mov     ds,ax                           ;dst: pvmsong segment:0
        mov     ah,3fh                          ;read file
        int     21h
        jc      .error

        mov     ah,3eh                          ;close fd
        int     21h
        jc      .error                          ;error? exit

        pop     ds
        ret

.error:
        mov     dx,msg_error_load               ;print error message and exit
        call    print_msg

        pop     ds

        mov     ax,4c02h
        int     21h

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

        in      al,21h                          ;Read primary PIC Interrupt Mask Register
        mov     [old_pic_imr],al                ;Store it for later
        mov     al,1111_1100b                   ;Mask off everything except IRQ 0
        out     21h,al                          ; and IRQ1 (timer and keyboard)

        sti
        ret

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
restore_irq:
        cli

        mov     al,[old_pic_imr]                ;Get old PIC settings
        out     21h,al                          ;Set primary PIC Interrupt Mask Register

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
        mov     word [pvm_offset],10h           ;update start offset
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
        int     16h                             ;Call BIOS keyboard interrupt
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

DATA    equ     0000_0000b
DATA_EXTRA equ  0010_0000b
DELAY   equ     0100_0000b
DELAY_EXTRA equ 0110_0000b
END     equ     1000_0000b

        int     3
        push    ax
        push    cx
        push    si
        push    ds
        push    es

        mov     ax,data                         ;vars in es
        mov     es,ax
        mov     ax,pvmsong                      ;song in ds
        mov     ds,ax

        sub     cx,cx                           ;cx=0... needed later
        mov     si,[es:pvm_offset]

        cmp     byte [es:pvm_wait],0
        je      .l0

        dec     byte [es:pvm_wait]
        jmp     .exit

.l0:
        lodsb                                   ;fetch command byte
        mov     ah,al
        and     al,1110_0000b                   ;al=command only
        and     ah,0001_1111b                   ;ah=command args only

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
        mov     cl,al                           ;new repeat value taken from prev. fetch
.repeat:
        lodsb
        out     0c0h,al
        loop    .repeat

        jmp     .l0                             ; start again. fetch next command


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.is_delay:
        dec     ah                              ;minus one, since we are returning
        mov     [es:pvm_wait],ah                ; from here now
        jmp     .exit

.is_delay_extra:
        lodsb                                   ;fetch wait from next byte
        dec     al                              ;minus one, since we are returning
        mov     [es:pvm_wait],al                ; from here now
        jmp     .exit

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
.is_end:
        mov     byte [es:pvm_wait],5            ;wait 5 cycles before starting again
        mov     word [es:pvm_offset],10h        ; beginning of song
        jmp     .exit_skip

.exit:
        mov     [es:pvm_offset],si
.exit_skip:

        pop     es
        pop     ds
        pop     si
        pop     cx
        pop     ax
        ret


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; IRQ
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
new_i08:
        call    song_tick

        add     word [cs:i08_counter],PIT_divider
        jnc     skip_old_i08
        db      0eah                            ;Jump far...
old_i08:        dd 0                            ; ...to Old INT 08 vector

skip_old_i08:
        push    ax
        mov     al,20h                          ;Send the EOI signal
        out     20h,al                          ; to the IRQ controller
        pop     ax

        iret                                    ;Exit interrupt

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
i08_counter:
        dw      0

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; section DATA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .data data

;messages
msg_title:      db 'pvmplayer v0.1 - riq/pvm',13,10,'$'
msg_help:       db 'usage:',13,10
                db '   pvmplayer songname.pvm',13,13,'$'
msg_loading:    db 'loading $'
msg_error_load: db 'error loading',13,10,'$'
msg_enter:      db 13,10

;vars
filename:
        resb    64                              ;64 bytes for the name

pvm_wait:                                       ;cycles wait
        db      0

pvm_offset:                                     ;pointer to next byte to read
        dw      0

old_pic_imr:
        db      0                               ;PIC IMR original value

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; section STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .pvmsong data
        resb    65536

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; section STACK
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .stack stack
        resb    1024
stacktop:
