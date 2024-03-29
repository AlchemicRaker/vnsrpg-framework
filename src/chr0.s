.segment "CHR0"

.export begin_chr0, font

;16 byte defines 1 tile
;8 byte are the first bit of each color in an 8x8 grid
;8 byte are the second bit of each color in an 8x8 grid
;1 byte is 8 bits, 1 row of a tile

begin_chr0:

tile0:
    .byte   %00000000   ; first bit
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000

    .byte   %00000000   ; second bit
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000

font:
.incbin "font.chr"

tile1:
    .byte   %11111111   ; first bit
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111

    .byte   %00000000   ; second bit
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000

tile2:
    .byte   %00000000   ; first bit
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000
    .byte   %00000000

    .byte   %11111111   ; second bit
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111

tile3:
    .byte   %11111111   ; first bit
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111

    .byte   %11111111   ; second bit
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111
    .byte   %11111111