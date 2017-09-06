; Settings for TASM
LOCALS @@
JUMPS
.8086  ; Ensure that only 8086 assembly code is used

; Timing settings:
IRQrate     = 60
PITdivider  = 19886 ; 1234DCh / IRQrate

; Handy macros
word0   equ (word ptr 0)
word2   equ (word ptr 2)
word4   equ (word ptr 4)

;;;;;;;;;;;;
;;;;;;;;;;;;
text    SEGMENT PARA PUBLIC

main:
    ASSUME CS:text,DS:nothing,ES:nothing
    xor ax, ax
    mov ds, ax
    
    ; Load the old INT 08 vector
    ; and install our own
    cli
     mov ax, OFFSET NewI08
     mov dx, cs ;SEG    NewI08
     xchg ax, [ds:8*4].word0
     xchg dx, [ds:8*4].word2
     mov OldI08.word0, ax
     mov OldI08.word2, dx
     
     ; Configure the PIT to
     ; issue IRQ at 60 Hz rate
     mov ax, PITdivider
     call SetupPIT
    sti
    
    mov ax, data
    mov ds, ax
    ASSUME DS:data
    mov [psp], es
    ; ^save program segment prefix, for it will be
    ; used for locating the commandline parameters
    
    call PlayerMain
    
    ; Silence each channel
    mov di, 300h
@@1:mov cx, di
    xor ax, ax
    call SetupAudio
    sub di, 100h
    jns @@1
    
    cli
     ; Reset PIT to defaults (~18.2 Hz)
     mov ax, 0 ; actually means 10000h
     call SetupPIT
     
     ; Restore the old INT 08 vector
     xor ax, ax
     mov ds, ax
     les si, [OldI08]
     mov [ds:8*4].word0, si
     mov [ds:8*4].word2, es
    sti
    
    ; Terminate program
    mov ax, 4C00h
    int 21h ; INT 21, AH=4Ch, AL=exit code
    
;;;;;;;;;;;;

PlayerMain:
    ASSUME CS:text, DS:data, ES:nothing
    ; Save the stack pointer for this call frame.
    ; DosErrorQuit restores it if an error happens.
    mov [songsp], sp
    ; Find the commandline parameter that contains
    ; the name of the file we want to play
    mov dx, 1
    call GetParamStr
    ; Exit if filename was not given
    mov dx, OFFSET UsageMsg
    test ax, ax
    jz PrintMessage
    ; Save filename
    mov FileNamePtr.word0, si
    mov FileNamePtr.word2, es
    mov FileNameLength, ax
    ; Prepare to address the file buffer
    mov ax, buffers
    mov es, ax
    ASSUME ES:buffers
    ; Try to open the file
    call SongFileOpen
    
    ; Set 40x25 color text mode
    mov ax, 1
    int 10h
    
    ; Print message
    mov dx, OFFSET PlayingMsg0
    call PrintMessage
    push ds
     lds dx, FileNamePtr
     call PrintMessage
    pop ds
    mov dx, OFFSET PlayingMsg1
    call PrintMessage
    
    ; Main loop
@@mainloop:
    hlt ; wait for IRQ
    ; Check it was timer IRQ
    mov al, 0
    lock xchg al, [IRQticked]
    test al, al
    jz @@2
    ; It was; advance the song.
    call SongTick
    call SongVisualize
    
@@2:
    ; Loop until some input is given
    mov ah, 1
    int 16h ; INT 16,AH=1, OUT:ZF=status
    jz @@mainloop
    
    ; Close input file
    call SongFileClose
    
    ; Read the input key
    xor ax, ax
    int 16h  ; INT 16,AH=0, OUT:AX=key
    ret

DosErrorQuit:
    mov sp, [songsp]
    ; ^Restore stack pointer to what was saved
    ; in PlayerMain. This, because error might
    ; have happened within a function call chain.
    ; It is our cheap equivalent of C++ "throw".
    xchg ax, bp ; save error code
    mov dx, OFFSET ErrorPart0
    call PrintMessage   ; print part0
    push ds
     lds dx, FileNamePtr
     call PrintMessage  ; print filename
    pop ds
    mov dx, OFFSET ErrorPart1
    call PrintMessage   ; print part1

    test bp, bp         ; analyze error code
    jns @@2
    and bp, 7FFFh       ; hardcoded error message
    mov dx, bp
    jmp @@1
@@2:cmp bp, 2
    mov dx, OFFSET DOSerror2
    je @@1
    cmp bp, 3
    mov dx, OFFSET DOSerror3
    je @@1
    cmp bp, 4
    mov dx, OFFSET DOSerror4
    je @@1
    cmp bp, 5
    mov dx, OFFSET DOSerror5
    je @@1
    mov dx, OFFSET UnprintableErr
@@1:call PrintMessage   ; print error message
    mov dx, OFFSET ErrorPart2
    ;jmp PrintMessage   ; print part2
PrintMessage:
    mov ah, 9
    int 21h
    ;^ INT 21, AH=9, DS:DX=Address
    ;  of $-terminated message
    ret

;;;;;;;;;;;;;;;;;;;;;;;;
; SONG PARSER & PLAYER ;
;;;;;;;;;;;;;;;;;;;;;;;;
SongTick:
    cmp [pending], 0
    jz @@read_event
    inc [pending]     ; approach zero
    ret
@@n:call SongFileReadByte
    neg al            ; -n
@@1:mov [pending], al ; -1
    jmp SongTick
@@c:; ignore the channel setup
    call SongFileReadWord
    jmp @@read_event
@@p:; ignore the pcm data
    call SongFileReadByte
    call SongFileReadWord
@@r:jz @@read_event
    call SongFileReadByte
    dec di
    jmp @@r
@@read_event:
    call SongFileReadByte
    cmp al, 0FFh ; submit row 1 times
    jz @@1
    cmp al, 0FDh ; submit row N times
    jz @@n
    cmp al, 0FEh ; setup channel type
    jz @@c
    cmp al, 0FBh ; setup PCM sample
    jz @@p
    cmp al, 20h
    jb @@default_event ; Alter channel
    ; Alter square wave (Ver3 only)
    ; AL.high4 = duty (2,4,8,12), ignored
    ; AL.low4  = volume (0-15)
    push ax
     ; Read channel number and the wave length
     call SongFileReadByte  ;Read channel
     push ax
      call SongFileReadWord ;Read wavelen
     pop cx
    pop ax
    jmp @@skip_ver1_fixes

@@default_event:
    ; AL = channel
    push ax
     call SongFileReadWord  ;Read wavelen
     call SongFileReadByte  ;Read volume
    pop cx
    cmp [fileversion], 1
    jne @@skip_ver1_fixes

    ; For SND version 1, wavelen
    ; is actually a frequency,
    ; and volume is 0..255
    shr al, 4 ; divide by 16 -> 0..15

    ; Calculate wavelen: 110000 / freq.
    push ax
     mov dx, 1     ; 110000 >> 16
     mov ax, 44464 ; 110000 & 0FFFFh
     cmp di, 2     ; Ensure that the quotient will
     jae @@2       ; not be too large to fit in a
     mov di, 2     ; 16-bit register (overflow)
@@2: div di
     xchg ax, di
    pop ax

@@skip_ver1_fixes:
    cmp cl, 4 ; Check channel is 0-3
    jae @@read_event
    and al, 0Fh
    mov dx, di
    mov ch, cl
    call SetupAudio
    jmp @@read_event

;;;;;;;;;;;;;;;;;
; SONG FILE I/O ;
;;;;;;;;;;;;;;;;;
SongFileOpen:
    push ds
     mov bx, FileNameLength
     lds si, FileNamePtr
     ; ^ Load Length before Ptr, because
     ; "lds" overwrites ds which is needed
     ; for accessing variables
     mov dx, si
     ; Put nul-terminator into filename
     mov byte ptr [bx+si], 0
     mov ax, 3D00h ; Open in read-only mode
     int 21h
     ;^ INT 21, AH=3Dh, AL=access mode,
     ; DS:DX=address of 0-terminated filename string
     ; Now change the trailing 0 to '$'
     ; so the filename can be printed.
     mov byte ptr [bx+si], '$'
    pop ds
    jc DosErrorQuit
    mov [songfd], ax ; Save file handle
    ; Read SND file header
    mov dx, OFFSET songhdr
    mov cx, 16
    call SongFileRawRead
    ; Verify header validicity
    mov ax, OFFSET Error_Fmt + 8000h
    cmp signature.word0, 4E53h ; 'SN'
    jne DosErrorQuit
    cmp signature.word2, 1A44h ; 'D^Z'
    jne DosErrorQuit
    ;cmp rate, IRQrate
    ;jne DosErrorQuit
    cmp channelcount, 0 ; Zero channels is an error.
    je DosErrorQuit
    cmp channelcount, 5 ; >5 channels: also an error.
    ja DosErrorQuit
    cmp fileversion, 1  ; Format: iNES
    je @@1
    cmp fileversion, 3  ; Format: nezplay
    jne DosErrorQuit
@@1:
    ret

SongFileClose:
    mov bx, [songfd]
    mov ah, 3Eh
    int 21h  ; INT 21, AH=3Eh, BX=handle
    ret

SongFileRawRead:
    ; DX = target, CX = byte count
    ; Uses: AX, BX
    push ds
     mov bx, [songfd]
     mov ax, SEG filebuffer
     mov ds, ax
     mov ah, 3Fh
     int 21h
     ;^ INT 21h, AH=3Fh
     ;  CX=number of bytes, DS:DX=buffer
    pop ds
    jc DosErrorQuit
    ret

SongFileFillBuffer:
    mov dx, OFFSET filebuffer
    mov cx, filebuf_size
    call SongFileRawRead
    mov [bufreadpos], 0
    mov [bufsize],    ax
    test ax, ax
    mov ax, OFFSET EndOfFile + 8000h 
    jz DosErrorQuit
SongFileReadByte:
    ; OUT: AX = byte
    ; Uses: BX, CX, DX
    mov bx, [bufreadpos]
    cmp bx, [bufsize]
    jae SongFileFillBuffer
    mov ah, 0
    mov al, filebuffer[bx]
    inc bx
    mov [bufreadpos], bx
    ret

SongFileReadWord:
    ; Out: DI = word
    ; Uses: AX, BX, CX, DX
    call SongFileReadByte
    xchg ax, di
    call SongFileReadByte
    xchg ah, al
    or di, ax
    ret


;;;;;;;;;;;;;;;;;
; VISUALIZATION ;
;;;;;;;;;;;;;;;;;

SongVisualize:
    push es
     les di, dword ptr [VisMem]
     ; Loop through each channel.
     ; Each is represented by a column
     ; that is 10 characters wide.
     mov si, 0
@@5:
     mov bx, si
     mov bp, ch_delta[si+bx]
     or bp, bp
     jz @@4a   
     mov bp, 2 ;number of spaces before
     js @@4
     mov bp, -1
@@4a:inc bp
@@4: 
     mov ax, ch_period[si+bx]
     call @@translate_period
     mov cl, ch_volume[si]
     mov ch, 0
     sub cx, 16
     neg cx
     call @@draw_column
     add di, 20
     inc si
     cmp si, 4
     jb @@5
    pop es
    ret
@@translate_period: ; aka. wavelen, or divider
    ; Make symbol for the period (0..3FFh).
    ; hz = 3579545/16/2/tandydivider
    ; hz = 2^((linearnote-34)/12)*440
    ; SOLVE linearnote
    ; v=1000 - 3 * (linearnote)
    ; v=610.3605-36*log2(1/tandydivider)
    fld f_notemul
    mov [f_temp].word0, ax
    fild dword ptr [f_temp]
    fld1
    fdivrp st(1), st
    fyl2x
    fadd f_noteadd
    fistp [f_temp]
    fwait
    mov ax, [f_temp].word0
    xor dx, dx
    mov bx, NumVisuals
    div bx  ; Scale to NumVisuals range
    mov bx, dx
    shl bx, 1
    mov ax, Visuals[bx] ; color & char
    ret
@@draw_column:
    ; Draw column.
    ; IN: ax = color and character
    ;     cx = number of blank lines
    ;     bp = number of spaces before
    rep_blanks MACRO
      xchg ax,si
      rep stosw
      xchg ax,si
    ENDM
    push si
     push di
     mov si,0720h
      mov dx,cx
@@1:  cmp di,17*40*2-1
      ja @@6
      or dx, dx
      jz @@2
      ; Draw blank column
      mov cx,10
      rep_blanks
      dec dx
      jmp @@3
@@2:  ; Draw colored column
      mov cx,bp
      jcxz @@2b
      rep_blanks
@@2b: mov cx,8
      rep stosw
      mov cx,2
      sub cx,bp
      jbe @@3
      rep_blanks
@@3:  
      add di,30*2
      jmp @@1
@@6: pop di
    pop si
    ret

;;;;;;;;;;;;;
;; UTILITY ;;
;;;;;;;;;;;;;
GetParamStr:
    ;; IN:  DX = Parameter string number
    ;; OUT: AX = Length, ES:SI = String pointer
    les di, dword ptr cmdline
    mov cl, es:[di]
    xor ch, ch
    inc di
    ; Loop while we've got space ahead
@@get_next_param:
    jcxz @@got_param_begin
@@skip_space:
    cmp byte ptr es:[di], ' '
    ja @@got_param_begin
    inc di
    loop @@skip_space
@@got_param_begin:
    mov si, di ; Save beginning of param
    jcxz @@got_param_end
@@wait_space:
    cmp byte ptr es:[di], ' '
    jbe @@got_param_end
    inc di
    loop @@wait_space
@@got_param_end:
    mov ax,di
    sub ax,si
    je @@done ; End if param is empty
    dec dx
    jnz @@get_next_param
@@done: ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HARDWARE I/O ROUTINES ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupPIT:
    ; AX = PIT clock period
    ;      (Divider to 1193180 Hz)
    push ax
     mov al, 34h
     out 43h, al
    pop ax
    out 40h, al
    mov al, ah
    out 40h, al
    ret

SetupAudio:
    ; CH = CHANNEL (0..3)
    ; AL = VOLUME (0..15)
    ; DX = PERIOD (inverse of frequency)
    ; USES: AX,BX,CX,DX,SI

    ; Fixed volume for channel 2
    cmp ch, 2
    jne @@2
    test al, al
    jz @@2
    mov al, 6
@@2:
    
    ; Save data for visualization
    mov bl, ch
    mov bh, 0
    mov si, bx
    mov ch_volume[si], al
    test al, al
    jz @@1
    add si, si
    mov bx, ch_period[si]
    sub bx, dx
    mov ch_delta[si], bx
    mov ch_period[si], dx
@@1:

IF 0
    ; The SN76489 chip has a ridiculous
    ; high lower limit on its allowed
    ; pitches. For channel 3 (bass),
    ; we use the standard PC speaker
    ; instead. This works because bass
    ; has a constant volume. This also
    ; leaves the Tandy channel 3 free
    ; for defining the noise pitch.
    ;
    ; Note that this is a tradeoff:
    ; If you use this, both the noises
    ; and the bass channel will have
    ; more range, but the bass will also
    ; be much louder than it should.
    ; If you prefer the bass be at
    ; a moderate volume, disable this
    ; code. It is disabled by default.
    
    cmp ch, 2
    je SetupPCspeaker ; Use PC speaker
    cmp ch, 3
    jne SetupSN76489
    ; Noise: Set pitch on channel 3
    push ax
     mov ax, dx ; multiply by 3
     add ax, ax
     add dx, ax
     shr dx, 4  ; divide by 16
     mov ch, 2  ; wl = inwl*3/16
     mov al, 0
     call SetupSN76489
    pop ax
    ; Noise 7: Copy pitch from channel 3.
    mov ch, 3
    mov dx, 7
ENDIF
    ;jmp SetupSN76489

SetupSN76489:
    ; IN: CH=CHANNEL,AL=VOLUME,DX=PERIOD
    cmp ch, 3
    jne @@checkpitchrange
    ; Noise 4 ~ period  84.7 (0-127)
    ; Noise 5 ~ period 169.5 (128-255)
    ; Noise 6 ~ period 339.0 (256-1023)
    mov cl, 7 ; divide by 128
    shr dx, cl
    add dl, 4
    cmp dx, 6
    jbe @@checkpitchrange
    mov dx, 6
@@checkpitchrange:
    ; If the pitch is too low, increase by an octave
    ; The SN76489 chip has a ridiculous high
    ; lower limit on its allowed pitches (109 Hz).
    cmp dx, 3FFh
    jbe @@4
    shr dx, 1
    jmp @@checkpitchrange
@@4:
    mov bx, OFFSET TandyVolumeTable
    xlatb      ; Translate volume
    or al, 90h ; Set bits for volume
    call @@out

    mov ax, dx ; Set period 4 low bits
    and al, 0Fh
    or al, 80h ; Set bits for period.lo
    call @@out

    mov ax, dx ; Set period 6 high bits
    mov cx, 4  ; ch:=0, cl:=4
    shr ax, cl
    and al, 3Fh
@@out:
    mov ah, ch ; Add channel
    aad 20h    ; al := al + ah * 20h
    out 0C0h, al
    ret

IF 0
SetupPCspeaker:
    ; Reprogram the standard PC speaker
    ; IN: AL=VOLUME, DX=PERIOD
    test al, al
    jz @@pcquiet
    mov al, 0B6h
    out 43h, al
    ; 3579545/16/2/tandydivider = 1193180/pcdivider
    ; Solve pcdivider --> we get ~32/3.
    xchg ax, dx
    mov bx, 32
    mul bx
    mov bx, 3
    div bx
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h   ; Enable sound
    or al, 3
    jmp @@s
@@pcquiet:
    in al, 61h   ; Disable sound
    and al, 0FCh
@@s:out 61h, al
    ret
ENDIF

;;;;;;;;;;;
;;; IRQ ;;;
;;;;;;;;;;;
    ASSUME CS:text,DS:nothing,ES:nothing

NewI08:; New INT 08 (timer IRQ) handler
    push ax
     mov [IRQticked],  1
     add [I08counter], PITdivider
     jnc SkipOldI08
    pop ax
    db 0EAh ; Jump far
OldI08 dd 0 ; Old INT 08 vector
SkipOldI08:
     mov al, 20h ; Send the EOI signal
     out 20h, al ; to the IRQ controller
    pop ax
    iret    ; Exit interrupt

IRQticked   db 0
I08counter  dw ?
; I08counter makes it possible to call the
; the old IRQ vector at the right rate.
; At every INT, it is incremented by:
;    10000h * (oldrate/newrate)
; Which happens to evaluate into the same
; as PITdivider when the oldrate is the
; standard ~18.2 Hz. Whenever it overflows,
; it's time to call the old IRQ handler.
; This ensures that the old IRQ handler is
; called at the standard 18.2 Hz rate.

text    ENDS

;;;;;;;;;;;;
;;;;;;;;;;;;
data    SEGMENT PARA PUBLIC
; Messages
UnprintableErr db 'Unprintable error$'
DOSerror2   db 'File not found$'
DOSerror3   db 'Path not found$'
DOSerror4   db 'Too many open files$'
DOSerror5   db 'Access denied$'
ErrorPart0  db '$'
ErrorPart1  db ': $'
ErrorPart2  db 13,10,'$'
Error_Fmt   db 'Not a valid SND file$'
EndOfFile   db 'End of file reached.$'
PlayingMsg0 db 'Playing $'
PlayingMsg1 db '. Hit a key to end.'
    db 10,10,10,10,10,10,10,10,10
    db 10,10,10,10,10,10,10,10,10
    db 'Player created by Joel Yliluoma'
    db 13,10,  'in July 2011, for Tandy 1000 and'
    db 13,10,  'assembler programming illustration.'
    db 13,10,10,'Thanks for watching!'
    db 13,10,   '                  '
    db          '[Click to subscribe!]$'
UsageMsg db 'Usage: TANDYSND file.snd'
    db 13,10,'$'

TandyVolumeTable equ $
    ; Translate linear volume into
    ; Tandy's 2dB increments volume
    ;   0  1  2  3  4  5  6  7
    db 15,11, 8, 7, 5, 4, 4, 3
    ;   8  9 10 11 12 13 14 15 
    db  2, 2, 1, 1, 1, 0, 0, 0

Visuals dw 51DBh,51B1h,51B0h, 45DBh,45B1h,45B0h
        dw 64DBh,64B1h,64B0h, 26DBh,26B1h,26B0h
        dw 32DBh,32B1h,32B0h, 63DBh,63B1h,63B0h
        dw 56DBh,56B1h,56B0h, 25DBh,25B1h,25B0h
        dw 42DBh,42B1h,42B0h, 14DBh,14B1h,14B0h
        dw 71DBh,71B1h,71B0h, 17DBh,17B1h,17B0h
        ;Color symbols for visualization
NumVisuals equ ($-Visuals)/2

FileNamePtr    dd 0 ; Location of fname
FileNameLength dw 0 ; Its length

songfd  dw 0 ; Handle of the SND file
songsp  dw 0 ; SP for song error returns

bufsize    dw 0  ; Amount of data in buffer
bufreadpos dw 0  ; Buffer reading position

pending    db 0  ; Playing delay control

cmdline dw 80h ; PSP offset to cmdline
psp     dw 0   ; Program Segment Prefix

f_notemul dq -36.0
f_noteadd dq 610.36054
f_temp    dq 0  ; FPU math temporary

ch_period dw 0,0,0,0 ; Visualization
ch_delta  dw 0,0,0,0
ch_volume db 0,0,0,0

VisMem  dw 40*2, 0B800h

data    ENDS


;;;;;;;;;;;;
;;;;;;;;;;;;
buffers SEGMENT PARA PUBLIC

filebuf_size equ 128
filebuffer   db filebuf_size dup (?)
songhdr      db 16 dup (?)
signature    equ (byte ptr songhdr+0)
fileversion  equ (byte ptr songhdr+4)
channelcount equ (byte ptr songhdr+5)
rate         equ (byte ptr songhdr+6)

buffers ENDS

;;;;;;;;;;;;
;;;;;;;;;;;;
END main
