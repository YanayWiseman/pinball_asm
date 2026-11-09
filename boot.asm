bits 16
org 0x7C00

start:
    ; Initialize segments and stack
    cli
    xor ax, ax

    mov ds, ax
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
    
draw_frame:
    ; draw bottom row
    mov ax, 150
    call draw_bottom_row_with_hole
    
    ; draw top row
    mov ax, 25
    call draw_row
    

    ; left column
    mov ax, 50
    call draw_column
    
    ; right column
    mov ax, 250
    call draw_column
    
    ; pre render the flippers
    mov al, 15                  
    mov dl, [left_flipper_state]                   
    call draw_left_flipper
                    
    mov dl, [right_flipper_state]                   
    call draw_right_flipper
             
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
        xor al, al
        mov dl, [left_flipper_state]
        call draw_left_flipper
        
        ; toggle the state
        xor byte [left_flipper_state], 1
        jmp redraw_left 
        
    toggle_right_flipper:
        ; erase current flipper by coloring it black
        xor al, al
        mov dl, [right_flipper_state]
        call draw_right_flipper
        
        ; toggle the state
        xor byte [right_flipper_state], 1
        jmp redraw_right
    
    redraw_left:
        mov al, 15
        mov dl, [left_flipper_state]
        call draw_left_flipper
        jmp no_key_pressed
    
    redraw_right:
        mov al, 15
        mov dl, [right_flipper_state]
        call draw_right_flipper
        jmp no_key_pressed        
    
    no_key_pressed:
        ; erase ball
        xor ax, ax
        call draw_ball
        
        ; calc velocity and position
        mov ax, [ball_vy]
        inc ax
        mov [ball_vy], ax
        
        mov ax, [ball_x]
        add ax, [ball_vx]
        mov [ball_x], ax
        
        mov ax, [ball_y]
        add ax, [ball_vy]
        mov [ball_y], ax
        
        ; wall collision check
        ; left wall (if x <= 51)
        cmp word [ball_x], 51
        jge check_right_wall
        mov word [ball_x], 51
        neg word [ball_vx]  ; reverse the direction
        
        check_right_wall: ; if x >= 247
            cmp word [ball_x], 247
            jle check_top_wall
            mov word [ball_x], 247
            neg word [ball_vx]
        
        check_top_wall: ; if y <= 26
            cmp word [ball_y], 26
            jge check_left_flipper
            mov word [ball_y], 26
            neg word [ball_vy]
            
        ; check left flipper (only if open)
        cmp byte [left_flipper_state], 1
        jne check_right_flipper
        
        check_left_flipper:
            cmp word [ball_x], 118
            jl check_right_flipper
            cmp word [ball_x], 136
            jg check_right_flipper
            cmp word [ball_y], 140
            jl check_right_flipper
            cmp word [ball_y], 152
            jg check_right_flipper
            
            ; left flipper hit
            mov word [ball_y], 138
            mov word [ball_vy], -8
            mov word [ball_vx], 3
            jmp check_bottom
        
        
        check_right_flipper:
            cmp byte [right_flipper_state], 1
            jne check_bottom
            
            cmp word [ball_x], 168
            jl check_bottom
            cmp word [ball_x], 181
            jg check_bottom
            cmp word [ball_y], 140
            jl check_bottom
            cmp word [ball_y], 152
            jg check_bottom
            
            ; right flipper hit
            mov word [ball_y], 138
            mov word [ball_vy], -8
            mov word [ball_vx], -3            
        
        check_bottom: ; if y < 160 reset to top
            cmp word [ball_y], 160
            jle render_ball
            
            ; reset position and velocity
            mov word [ball_x], 100
            mov word [ball_y], 40
            mov word [ball_vx], 2
            mov word [ball_vy], 0
            
        
                
        render_ball:
            mov ax, 15
            call draw_ball
            
            ; delay
            sti
            hlt
            jmp game_logic
    

    
draw_row:      
    mov bx, 320
    mul bx
    mov di, ax  ; y
    ; Color 15 = white
    mov al, 15
    
    ; offset = y * 320 + x
    mov cx, 320
    rep stosb

    ret
 
draw_column:                              
    mov di, ax  ; x
    mov al, 15    
    
    mov cx, 200
    draw_column_loop:
        stosb
        add di, 319
        
        loop draw_column_loop
    
    ret
    
draw_bottom_row_with_hole:
    mov bx, 320
    mul bx
    mov si, ax  ; y
    mov al, 15
    mov di, si
    add di, 50
    
    mov cx, 71
    rep stosb
    
    add di, 59
    mov cx, 71
    rep stosb   
    ret

; color in al and state in dl                                
draw_left_flipper:  
    mov di, 48120
    cld
    jmp draw_flipper
    
draw_right_flipper:
    mov di, 48180
    std
    ; fall through
    
draw_flipper:
    test dl, 1
    mov dx, 320
    jz flipper_step_ready
    neg dx
    
flipper_step_ready:
    mov cx, 16

flipper_loop:
    stosb
    test cl, 1
    jnz flipper_skip_step
    add di, dx

flipper_skip_step:
    loop flipper_loop
    
    cld
    ret
        
draw_ball:    
    mov cl, al
    
    mov ax, [ball_y]
    mov bx, 320
    mul bx
    add ax, [ball_x]
    mov di, ax
    mov al, cl
    mov ah, al
    
    stosw
    add di, 318
    stosw

    ret
    
left_flipper_state db 0
right_flipper_state db 0

ball_x dw 100
ball_y dw 40
ball_vx dw 2
ball_vy dw 0
        

; Pad to 510 bytes, then add boot signature
times 510 - ($ - $$) db 0
dw 0xAA55