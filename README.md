# Bootsector Pinball

A tiny pinball game written in x86 assembly that fits in a single 512 byte boot sector. No OS, no libraries, just BIOS interrupts and VGA mode 13h.

## What it does

- Runs in 16 bit real mode, loaded straight from the boot sector at 0x7C00
- Draws the table in VGA mode 13h (320x200, 256 colors)
- Ball with gravity, wall bouncing, and a gap at the bottom where you lose it
- Two flippers you control using the keyboard
- Ball resets to the top when it falls through the hole

## Controls

| Key | Action |
|-----|--------|
| `A` | Toggle left flipper |
| `D` | Toggle right flipper |

A flipper only kicks the ball when it's in the raised position.

## Build

You need [NASM](https://www.nasm.us/):

```
nasm -f bin pinball.asm -o pinball.bin
```

## Run

With QEMU:

```
qemu-system-i386 -drive format=raw,file=pinball.bin
```

## How it works

- Graphics are written directly to the VGA framebuffer at segment 0xA000
- Ball position and velocity are stored as words at the end of the program
- Gravity adds 1 to the vertical velocity every frame
- Flipper hits are simple bounding box checks, a hit sets a fixed upward velocity and a sideways push towards the center
- The program is padded to 510 bytes and ends with the 0xAA55 boot signature

## Ideas for later

- Score counter
- Better flipper physics
- obstacles
