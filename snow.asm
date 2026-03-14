; snow.asm - C64 Snowflakes Demo
; 6502 assembly for Commodore 64
; 8 different falling snowflake sprites
;
; Memory layout:
;   $0801-$080D  BASIC stub (10 SYS 2062)
;   $080E-$08FF  Machine code + tables
;   $0900-$0AFF  Sprite data (8 x 64 bytes)
;
; Build: acme snow.asm

        !cpu 6510
        !to "snow.prg", cbm

; Zero-page variables
XPOS    = $60           ; X positions for sprites 0-7 ($60-$67)
YPOS    = $68           ; Y positions for sprites 0-7 ($68-$6F)
SPEED   = $70           ; Fall speeds for sprites 0-7 ($70-$77)
RND     = $78           ; LFSR pseudo-random byte

; VIC-II registers
VICBASE = $D000

; ---------------------------------------------------------------
; BASIC stub at $0801: 10 SYS 2062
; ---------------------------------------------------------------
        * = $0801
        !byte $0c, $08          ; pointer to next BASIC line ($080C)
        !byte $0a, $00          ; line number 10
        !byte $9e               ; SYS token
        !text " 2062"           ; address 2062 = $080E
        !byte $00               ; end of BASIC line
        !byte $00, $00          ; end of BASIC program

; ---------------------------------------------------------------
; Main code starts at $080E (= decimal 2062)
; ---------------------------------------------------------------
        * = $080E

START:
        ; Clear screen using KERNAL routine
        jsr $E544

        ; Set border and background to black
        lda #0
        sta $D020
        sta $D021

        ; Initialise LFSR seed to non-zero
        lda #$A5
        sta RND

        ; Combined init loop: set sprite colors, pointers, positions, speeds
        ldx #7
INITLP: lda #1                  ; white
        sta $D027,x             ; sprite colour
        lda PTRTAB,x
        sta $07F8,x             ; sprite data pointer
        lda IXTAB,x
        sta XPOS,x              ; initial X
        lda IYTAB,x
        sta YPOS,x              ; initial Y
        lda ISTAB,x
        sta SPEED,x             ; fall speed
        dex
        bpl INITLP

        ; Enable all 8 sprites
        lda #$FF
        sta $D015

        ; All sprites in left 256 pixels (X MSB = 0)
        lda #0
        sta $D010

; ---------------------------------------------------------------
; Main animation loop
; ---------------------------------------------------------------
MAIN:
        ; Wait for raster line 200 (ensures one update per frame)
        lda #200
WAIT:   cmp $D012
        bne WAIT

        ldx #7
UPDATE:
        ; Move sprite down by its speed
        lda YPOS,x
        clc
        adc SPEED,x
        sta YPOS,x

        ; Off bottom of screen? (Y >= 252)
        cmp #252
        bcc WRITE

        ; Reset to top
        lda #28
        sta YPOS,x

        ; New pseudo-random X position using 8-bit Fibonacci LFSR
        lda RND
        asl
        bcc NOBIT
        eor #$1D
NOBIT:  sta RND
        and #$7F
        adc #30                 ; X range: 30-157 (+ carry 0 or 1)
        sta XPOS,x

WRITE:
        ; Update VIC-II sprite position registers
        ; Sprite N: X at $D000+N*2, Y at $D001+N*2
        txa
        asl
        tay
        lda XPOS,x
        sta $D000,y
        lda YPOS,x
        sta $D001,y

        dex
        bpl UPDATE

        jmp MAIN

; ---------------------------------------------------------------
; Initialisation tables (8 entries each)
; ---------------------------------------------------------------

        ; Sprite data pointers: address / 64
        ; $0900/64=36, $0940/64=37, ..., $0AC0/64=43
PTRTAB: !byte 36, 37, 38, 39, 40, 41, 42, 43

        ; Initial X positions (spread across visible screen)
IXTAB:  !byte  48, 100, 152, 200,  72, 124, 176,  24

        ; Initial Y positions (staggered vertically)
IYTAB:  !byte  28,  60,  90, 120,  45,  75, 105, 135

        ; Fall speeds in pixels per frame (1 = slow, 2 = fast)
ISTAB:  !byte   1,   2,   1,   2,   1,   2,   1,   2

; ---------------------------------------------------------------
; Sprite data area — 8 snowflakes, 64 bytes each (63 used + 1 pad)
; All sprites placed on 64-byte boundaries within VIC bank 0
; ---------------------------------------------------------------
        * = $0900

; --- Sprite 0: Simple + cross (horizontal and vertical arms) ---
; |...........X............|
; |XXXXXXXXXXXXXXXXXXXXXXXX|
; |...........X............|
        !byte $00,$10,$00, $00,$10,$00, $00,$10,$00
        !byte $00,$10,$00, $00,$10,$00, $00,$10,$00
        !byte $00,$10,$00, $00,$10,$00, $00,$10,$00
        !byte $00,$10,$00
        !byte $ff,$ff,$ff                           ; row 10: full horizontal
        !byte $00,$10,$00
        !byte $00,$10,$00, $00,$10,$00, $00,$10,$00
        !byte $00,$10,$00, $00,$10,$00, $00,$10,$00
        !byte $00,$10,$00, $00,$10,$00, $00,$10,$00
        !byte $00                                   ; padding

        * = $0940
; --- Sprite 1: × diagonal cross ---
; |.X...................X..|
; |..X.................X...|
        !byte $40,$00,$04, $20,$00,$08, $10,$00,$10
        !byte $08,$00,$20, $04,$00,$40, $02,$00,$80
        !byte $01,$01,$00, $00,$82,$00, $00,$44,$00
        !byte $00,$28,$00
        !byte $00,$10,$00                           ; row 10: centre
        !byte $00,$28,$00
        !byte $00,$44,$00, $00,$82,$00, $01,$01,$00
        !byte $02,$00,$80, $04,$00,$40, $08,$00,$20
        !byte $10,$00,$10, $20,$00,$08, $40,$00,$04
        !byte $00  ; padding

        * = $0980
; --- Sprite 2: 6-arm star (arms at 0°,60°,120°,180°,240°,300°) ---
; |........................|
; |......X.........X.......|
; |.XXXXXXXXXXXXXXXXXXXXX..|
        !byte $00,$00,$00, $02,$00,$80, $02,$00,$80
        !byte $01,$01,$00, $01,$02,$00, $00,$82,$00
        !byte $00,$82,$00, $00,$4c,$00, $00,$28,$00
        !byte $00,$28,$00
        !byte $7f,$ff,$fc                           ; row 10: full horizontal arm
        !byte $00,$28,$00
        !byte $00,$28,$00, $00,$6c,$00, $00,$82,$00
        !byte $00,$82,$00, $01,$01,$00, $01,$00,$80
        !byte $02,$00,$80, $00,$00,$00, $00,$00,$00
        !byte $00  ; padding

        * = $09C0
; --- Sprite 3: 6-arm star with mid-arm branches ---
; Branches perpendicular to each arm at half-length
        !byte $00,$00,$00, $02,$00,$80, $02,$00,$80
        !byte $01,$01,$00, $01,$02,$00, $00,$aa,$00
        !byte $01,$c7,$00, $02,$4c,$80, $02,$28,$80
        !byte $02,$28,$80
        !byte $7f,$ff,$fc                           ; row 10
        !byte $02,$28,$80
        !byte $02,$28,$80, $02,$6c,$80, $01,$c7,$00
        !byte $00,$aa,$00, $00,$82,$00, $01,$01,$00
        !byte $01,$00,$80, $02,$00,$80, $00,$00,$00
        !byte $00  ; padding

        * = $0A00
; --- Sprite 4: 6-arm star with forked tips ---
        !byte $01,$01,$00, $0a,$00,$a0, $06,$00,$c0
        !byte $01,$01,$00, $01,$02,$00, $00,$82,$00
        !byte $00,$82,$00, $00,$4c,$00, $00,$28,$00
        !byte $40,$28,$04
        !byte $3f,$ff,$f8                           ; row 10
        !byte $40,$28,$04
        !byte $00,$28,$00, $00,$6c,$00, $00,$82,$00
        !byte $00,$82,$00, $01,$01,$00, $03,$00,$c0
        !byte $05,$00,$a0, $00,$81,$00, $00,$00,$00
        !byte $00  ; padding

        * = $0A40
; --- Sprite 5: Diamond (rotated square outline) ---
; |........................|
; |...........X............|
; |..........X.X...........|
; |.X.................X....|
; |..X.................X...|
        !byte $00,$00,$00, $00,$10,$00, $00,$28,$00
        !byte $00,$44,$00, $00,$82,$00, $01,$01,$00
        !byte $02,$00,$80, $04,$00,$40, $08,$00,$20
        !byte $10,$00,$10
        !byte $20,$00,$08                           ; row 10: widest point
        !byte $10,$00,$10
        !byte $08,$00,$20, $04,$00,$40, $02,$00,$80
        !byte $01,$01,$00, $00,$82,$00, $00,$44,$00
        !byte $00,$28,$00, $00,$10,$00, $00,$00,$00
        !byte $00  ; padding

        * = $0A80
; --- Sprite 6: 6-arm star with long perpendicular branches ---
        !byte $00,$00,$00, $02,$00,$80, $02,$30,$80
        !byte $01,$c9,$00, $03,$07,$00, $04,$82,$80
        !byte $08,$82,$40, $08,$4c,$20, $08,$28,$20
        !byte $08,$28,$20
        !byte $7f,$ff,$fc                           ; row 10
        !byte $08,$28,$20
        !byte $08,$28,$20, $08,$6c,$20, $04,$82,$40
        !byte $02,$82,$80, $01,$c7,$00, $01,$29,$00
        !byte $01,$10,$80, $02,$00,$80, $00,$00,$00
        !byte $00  ; padding

        * = $0AC0
; --- Sprite 7: 8-arm star (octagonal, arms at 45° intervals) ---
; |........................|
; |...........X............|
; |.....X.....X.....X......|
; |......X....X....X.......|
        !byte $00,$00,$00, $00,$10,$00, $00,$10,$00
        !byte $00,$10,$00, $04,$10,$40, $02,$10,$80
        !byte $01,$11,$00, $00,$92,$00, $00,$54,$00
        !byte $00,$38,$00
        !byte $3f,$ff,$f8                           ; row 10
        !byte $00,$38,$00
        !byte $00,$54,$00, $00,$92,$00, $01,$11,$00
        !byte $02,$10,$80, $04,$10,$40, $00,$10,$00
        !byte $00,$10,$00, $00,$10,$00, $00,$00,$00
        !byte $00  ; padding
