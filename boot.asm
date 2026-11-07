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
    call draw_bottom_row_with_hole
    add sp, 2
    
    xor dx, dx
    
    ; draw top row
    mov ax, 25
    push ax
    call draw_row
    add sp, 2
    

    ; left column
    mov ax, 50
    push ax
    call draw_column
    add sp, 2
    
    ; right column
    mov ax, 250
    push ax
    call draw_column
    add sp, 2
    
    ; pre render the flippers
    mov ax, 15                  
    push ax
    xor ax, ax
    mov al, [left_flipper_state]
    push ax                     
    call draw_left_flipper
    add sp, 4

    mov ax, 15                
    push ax
    xor ax, ax
    mov al, [right_flipper_state]
    push ax                    
    call draw_right_flipper
    add sp, 4
             
game_logic:
    mov ah, 0x01
    int 16h
    jz no_key_pressed
    
    mov ah, 0x00
    int 16h
    
    ; a key was entered
    cmp al, 'a'
    je toggle_left_flipper
    
    cmp al, 'd'
    je toggle_right_flipper
    
    jmp no_key_pressed
    
    toggle_left_flipper:
        ; erase current flipper by coloring it black
        mov ax, 0
        push ax
        xor ax, ax
        mov al, [left_flipper_state]
        push ax
        call draw_left_flipper
        add sp, 4
        
        ; toggle the state
        xor byte [left_flipper_state], 1
        jmp redraw_left 
        
    toggle_right_flipper:
        ; erase current flipper by coloring it black
        mov ax, 0
        push ax
        xor ax, ax
        mov al, [right_flipper_state]
        push ax
        call draw_right_flipper
        add sp, 4
        
        ; toggle the state
        xor byte [right_flipper_state], 1
        jmp redraw_right
    
    redraw_left:
        mov ax, 15
        push ax
        xor ax,  ax
        mov al, [left_flipper_state]
        push ax
        call draw_left_flipper
        add sp, 4
        jmp no_key_pressed
    
    redraw_right:
        mov ax, 15
        push ax
        xor ax, ax
        mov al, [right_flipper_state]
        push ax
        call draw_right_flipper
        add sp, 4
        jmp no_key_pressed        
    
    no_key_pressed:
        ; ball logic
        delay:
            sti
            hlt
            loop game_logic
    
    jmp game_logic
      
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
    
draw_bottom_row_with_hole:
    push bp
    mov bp, sp
    
    mov ax, [bp + 4]  ; y
    mov bx, 320
    mul bx
    mov si, ax
    mov al, 15
    
    mov cx, 71
    left_loop:
        mov di, si
        add di, cx
        add di, 49
        mov [es:di], al
        loop left_loop
    
    mov cx, 71
    right_loop:
        mov di, si
        add di, cx
        add di, 179
        mov [es:di], al
        loop right_loop    
    
    mov sp, bp
    pop bp
    ret
                            
; bp+4 = left flipper state, bp+6 = color    
draw_left_flipper:
    push bp
    mov bp, sp
    
    mov al, [bp + 6]  ; color
    mov si, 150 * 320 + 120
    mov cx, 16  ; flipper length
    mov dx, [bp + 4]  ; flipper state
    cmp dx, 1
    je left_open
    
    left_closed:
        mov [es:si], al
        add si, 1
        test cx, 1  ; if cx is odd we skip adding 320 to si
        jnz skip_closed
        add si, 320 ; slope down
        skip_closed:
            loop left_closed
            jmp done_with_left
        
    
    left_open:
        mov [es:si], al
        add si, 1
        test cx, 1
        jnz skip_open
        sub si, 320
        skip_open:
            loop left_open
            jmp done_with_left
     
    done_with_left:
        mov sp, bp
        pop bp
        ret
    
; bp+4 = right flipper state, bp+6 = color
draw_right_flipper:            
    push bp
    mov bp, sp
    
    mov al, [bp + 6]  ; color
    mov si, 150 * 320 + 180
    mov cx, 16  ; flipper length
    mov dx, [bp + 4]  ; flipper state
    cmp dx, 1
    je right_open
    
    right_closed:
        mov [es:si], al
        sub si, 1
        test cx, 1  ; if cx is odd we skip adding 320 to si
        jnz skip_closed_right
        add si, 320 ; slope down
        skip_closed_right:
            loop right_closed
            jmp done_with_right
        
    
    right_open:
        mov [es:si], al
        sub si, 1
        test cx, 1
        jnz skip_open_right
        sub si, 320
        skip_open_right:
            loop right_open
            jmp done_with_right
     
    done_with_right:
        mov sp, bp
        pop bp
        ret
    
hang:
    hlt
    jmp hang
    
left_flipper_state  db 0
right_flipper_state db 0
        

; Pad to 510 bytes, then add boot signature
times 510 - ($ - $$) db 0
dw 0xAA55