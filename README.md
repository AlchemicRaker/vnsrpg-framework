# vnsrpg-framework
This is a game framework I am creating for quickly bootstrapping NES games.
It specifically targets **MMC3** cartridges (**TXROM** / **iNES mapper 4**), which I find to be a healthy mix of new-mapper capabilities and classic NES results.
This framework heavily embraces the **cc65** assembler, **ca65**, and the macro capabilities it provides for an improved coding experience.

## Bank System
The framework provides a straightforward way to navigate MMC3 PRG banks, with a handful of macros like `fjmp` (far jump from static code into any bank), `bjmp` (bank jump from bank code into any other bank), and `fjsr` (far jsr, a cross-bank `jsr` variant).

You should be comfortable putting Scenes and infrequently used subroutines into their own banks.  Static PRG should be reserved for NMI and IRQ code (which need to always be available), and subroutines commonly used by all scenes (avoid bank-switching time penalties).

### Use the Linker
In txrom.cfg you can mark banked memory with `$NNBB`, where NN is bank 0 through bank 63 (as stored in ROM), and BB selects between the two PRG windows `$06` and `$07` (as selected by `MMC3CTRL`).
This lets us easily look up what bank any label is in using `.bank(somewhere_far_away)`, and makes it easy to move labeled code between banks during development.

## Scene System
This framework provides an opinionated way to organize your game.
**Scenes** take full control of the NES resources: NMI interrupt (vblank effects), the IRQ (hblank effects), and the Main game code.
One scene can be active at a time, and the scene is responsible for queueing up another scene at the appropriate time.
NMI, IRQ, and Main are all hooked via address references in RAM.

#### Example Scene Usage
To start a scene, you may set the Main hook to `demo_scene_load_point`.
Once the main loop runs, it will jump into `demo_scene_load_point`, where you can hook your `demo_scene_nmi` into NMI, set up your IRQ table, select banks, load nametables, etc.
You will end it by changing the Main hook to `demo_scene_main_point`, which will run on the following frame, now that you have set up the resources the way you want them.

#### Why Organize This Way?
Other consoles are performant enough to handle multiple layers of code and visuals that control the screen, but that is rarely the case with the NES.
If desired, scenes may still be organized in a stack and scenes may still contain multiple layers of control, but that is intimately tied with the specific scene and is not the job of the scene system.

### Main Hook
You normally want to start processing the main game loop code immediately following the vblank, and that's exactly what this does.
This system plays nicely with NMI in regards to lag: if the loop takes more than a frame, the game will quietly lag for 1 frame and resume at normal speed on the following frame.
Push your scene's main loop address into `next_scene_point`, and bank into `next_scene_bank`:
```
    ldstword .bank(demo_scene_load_point), next_scene_bank
    ldstword demo_scene_load_point, next_scene_point
```

You may want your scene to run different sets of code at different times.
In my example, I have one label that loads the scene resources, and another label that runs the main loop.
At the end of `demo_scene_load_point`, I change `next_scene_point`.
```
    ldstword .bank(demo_scene_main_point), next_scene_bank
    ldstword demo_scene_main_point, next_scene_point
    rts
```

End your main loop with `rts`, and the framework will wait until the next NMI completes running before jumping into `next_scene_point` again.

### NMI Hook
This should be in your static code, and you can hook it at `scene_nmi`:
```
    ldstword demo_scene_nmi, scene_nmi
```

At the state of the A, X, Y, and S registers will all be saved and restored by the framework, so all you need to do is `rts` and the framework will do the rest.
After your NMI code runs, the framework takes a short moment to queue up the first entry in the irq scanline table, so if you are using any irq effects you'll want to set up the irq table your NMI handler.


### IRQ Table
The table is built by loading addresses into one table, and scanline offsets in another.  This example loads 4 irq hooks into the table, for $40, $80, $A0, and $C0:
```
    ; build an irq table
    ldstword demo_scene_irq1, irq_table_address
    ldst #$3E, irq_table_scanline               ;-1 for first irq timinig

    ldstword demo_scene_irq2, irq_table_address+2
    ldst #3F irq_table_scanline+1

    ldstword demo_scene_irq3, irq_table_address+4
    ldst #$3F, irq_table_scanline+2

    ldstword demo_scene_irq4, irq_table_address+6
    ldst #$1F, irq_table_scanline+3

    ldst #$FF, irq_table_scanline+4 ; stub the end with FF
```

As with the NMI Hook, the state of A, X, Y, and S registers will be saved and restored by the framework, so just `rts` to end the interrupt.
The framework will always queue up the next interrupt in the table when one completes; put $FF at the end of the table to stop any more from firing during that frame.

Scrolling and bank switching are common and easy hblank tasks.

#### Mid-Frame Palette Updates
This framework offers palette updates macros, for updating palettes during hblanks.
The timing is delicate, so the CPU will need to be in a reduced-jitter state (3-cycle commands or less), and there are some visual artifacts on the right and possibly left side of the screen depending on how many colors are being updated.
If updating one palette color, there will be a ~16 pixel streak of bg color on the far right.
If updating two sequential palette colors, the third tile on the next row must all use the bg color; in addition to the streak on the right there will also be a 16 pixel streak of bg color on the far left, followed by 8 more pixels of bg color from the third tile.
Lastly, if updating any palette colors, sprites in the following line will be corrupted, so it is best to disable sprite rendering for that row.

This is not acceptable for many games, but if there is sufficient padding or use of bg colors on the sides, this may enhance visuals in the center of the screen.

`demo_scene_irq1` is positioned for scanline $40, updates palette entry $01, and sets the new color $2C.
`demo_scene_irq3` is on scanline $C0, updates palette entry $02 (and $03), with the new colors $20 and $21.
```
.proc demo_scene_irq1
    color_change_irq $40, $01, $2C
.endproc

.proc demo_scene_irq3
    color_change_irq $C0, $02, $20, $21
.endproc
```

*TODO: Provide an easy way to 'soften' the CPU during an hblank, so that the jitter of the next IRQ is 0 to 3 CPU cycles max.*

### Sprite System
The sprite system is currently in planning.
Current plan is to provide a table of addresses that are called every frame, for keeping sprites updated and animated.
An incrementing register will be passed into each of these calls, so that one function may be used to drive several sprites.

## Audio System
(todo)

### Audio Toolchain
(todo)

## Graphics System
(todo)

### Graphics Toolchain
(todo)


