bits 16
org 0x7C00

start:
    ; Initialize segments and stack
    cli
    xor ax, ax

    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    sti
    cld

    ; Set VGA mode 13h: 320x200, 256 colors
    mov ax, 0x0013
    int 0x10

    ; VGA framebuffer starts at segment A000
    mov ax, 0xA000
    mov es, ax
    
    ; row setup
    mov ax, 150
    mov bx, 320
    mul bx
    mov si, ax
    ; Color 15 = white
    mov al, 15

    ; offset = y * 320 + x
            
draw_frame:
    ; draw bottom row
    mov ax, 150
    push ax
    call draw_row
    add sp, 2
    
    ; draw top row
    mov ax, 25
    push ax
    call draw_row
    add sp, 2
    
    mov ax, 50
    push ax
    call draw_column
    add sp, 2
    
    mov ax, 250
    push ax
    call draw_column
    add sp, 2
             
    ; here we need to  make a hole in the bottom row and create the diagonal flippers with open/closed states
    
    ; exit
    jmp hang

    
draw_row:
    push bp
    mov bp, sp
    
    mov ax, [bp + 4]  ; y
    
    mov bx, 320
    mul bx
    mov si, ax
    ; Color 15 = white
    mov al, 15

    ; offset = y * 320 + x
    mov cx, 320
    draw_line:
        mov di, si
        add di, cx

        mov [es:di], al
        loop draw_line
        
    mov sp, bp    
    pop bp
    ret
 
draw_column:
    push bp
    mov bp, sp
    
    mov dx, [bp + 4]  ; x
    mov di, dx
    mov al, 15    
    
    mov cx, 200
    draw_column_loop:
        mov [es:di], al
        add di, 320
        
        loop draw_column_loop
    
    
    mov sp, bp
    pop bp
    ret            

hang:
    hlt
    jmp hang        

; Pad to 510 bytes, then add boot signature
times 510 - ($ - $$) db 0
dw 0xAA55