;
; Reusing code and comments from Paku Paku game.
; http://www.deathshadow.com/pakuPaku
;

;       Detecting which video card is present is kinda tricky...
;       but thankfully they did something smart with int 0x10.
;       Calls to unknown subfunctions just RET leaving registers
;       intact, so if you call a VGA function that you know changes
;       a register, and the register doesn't change, it's not a VGA.
;       Call a EGA function ditto, ditto... finally check if we're in
;       a monochrome display mode, that's MDA.
;
;       Unfortunately there's no known reliable check for a CGA since
;       newer cards pretend to be one -- but if we eliminate
;       'everything else' from the list, it must be CGA.

bits    16
cpu     8086

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; CODE
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
section .text
;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; Macros and defines
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
VIDEOCARD_MDA           equ 0
VIDEOCARD_CGA           equ 1
VIDEOCARD_PCJR          equ 2
VIDEOCARD_TANDY1000     equ 3
VIDEOCARD_TANDYSLTL     equ 4
VIDEOCARD_EGA           equ 5
VIDEOCARD_VGA           equ 6
VIDEOCARD_MCGA          equ 7

;
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
; detect_card:
; output:
; al =  0 -> MDA
;       1 -> CGA
;       2 -> PCjr
;       3 -> Tandy 1000
;       4 -> Tandy SL/TL
;       5 -> EGA
;       6 -> VGA
;       7 -> MCGA
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-;
global detect_card
detect_card:
        mov     ax,0x1200
        mov     bl,0x32                 ;VGA only enable video
        int     0x10
        cmp     al,0x12                 ;VGA returns 0x12, all others leave it unmodified!
        jne     .notVGA                 ;not a vga, test for EGA
                                        ; VGA, or is it? test for MCGA
        xor     bl,bl                   ;null BL so it's set up for non-PS/2
        mov     ax,0x1a00
        int     0x10
        cmp     bl,0x0a                 ;MCGA returns 0x0a..0x0c
        jb      .isVGA
        cmp     bl,0x0c
        jg      .isVGA
        mov     al,VIDEOCARD_MCGA
        ret
.isVGA:
        mov     al,VIDEOCARD_VGA
        ret
.notVGA:                                ;We eliminated VGA, so an EGA/VGA true must be EGA
        mov     ah,0x12
        mov     bl,0x10                 ;EGA/VGA get configuration info
        int     0x10
        and     bl,0x03                 ;EGA/VGA returns a 0..3 value here
        jz      .notEGA                 ;not a VGA, test for MDA
        mov     al,VIDEOCARD_EGA
        ret
.notEGA:                                ;MDA all we need to detect is video mode 7
        mov     ah,0x0f                 ;get Video mode
        int     0x10
        cmp     al,0x07
        jne     .notMDA
        mov     al,VIDEOCARD_MDA
        ret
.notMDA:                                ;not MDA, check for Jr.
        mov     ax,0xffff
        mov     es,ax
        mov     di,0x000e               ;second to last byte PCjr/Tandy BIOS info area
        cmp     byte [es:di],0xfd       ;ends up 0xfd only on the Jr.
        jne     .notJr
        mov     al,VIDEOCARD_PCJR
        ret
.notJr:                                 ;not junior, test for tandy
        cmp     byte [es:di],0xff       ;all tandy's return 0xff here
        jne     .notTandy
        mov     ax,0xfc00
        mov     es,ax
        xor     di,di
        cmp     byte [es:di],0x21
        jne     .notTandy
        mov     ah,0xc0                 ;test for SL/TL
        int     0x15                    ;Get System Environment
        jnc     .tandySLTL              ;early Tandy's leave the carry bit set, TL/SL does not
        mov     al,VIDEOCARD_TANDY1000
        ret
.tandySLTL:
        mov     al,VIDEOCARD_TANDYSLTL
        ret
.notTandy:
        mov     al,VIDEOCARD_CGA        ;all other cards eliminated, must be CGA
        ret

