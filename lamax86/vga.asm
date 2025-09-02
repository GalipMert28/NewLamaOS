; VGA Graphics Mode Initialization Module

; Initialize VGA graphics mode
vga_init:
    push ax
    push bx
    push cx
    push dx
    
    ; Save current video mode
    mov ah, 0x0F           ; Get current video mode
    int 0x10
    mov [original_video_mode], al
    
    ; Set VGA graphics mode 320x200 256 colors (Mode 13h)
    mov ah, 0x00           ; Set video mode
    mov al, 0x13           ; Mode 13h (320x200, 256 colors)
    int 0x10
    
    ; Verify mode was set
    mov ah, 0x0F           ; Get current video mode
    int 0x10
    cmp al, 0x13
    jne .vga_error
    
    ; Clear graphics screen with blue background
    call clear_graphics_screen
    
    ; Draw test pattern
    call draw_test_pattern
    
    ; Display success message in text area
    mov si, vga_success_msg
    call print_graphics_text
    
    ; Wait for keypress before continuing
    mov si, press_key_msg
    call print_graphics_text
    call wait_for_key
    
    ; Restore text mode for continued boot process
    mov ah, 0x00           ; Set video mode
    mov al, 0x03           ; 80x25 color text mode
    int 0x10
    
    mov si, vga_complete_msg
    call print_string
    
    jmp .done
    
.vga_error:
    ; Restore original mode on error
    mov ah, 0x00
    mov al, [original_video_mode]
    int 0x10
    
    mov si, vga_error_msg
    call print_string
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Clear graphics screen with solid color
clear_graphics_screen:
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    ; Set ES to VGA memory segment
    mov ax, 0xA000
    mov es, ax
    xor di, di             ; Start at beginning of VGA memory
    
    ; Fill screen with blue color (color 1)
    mov al, 0x01           ; Blue color
    mov cx, 64000          ; 320x200 pixels
    rep stosb              ; Fill VGA memory
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Draw a test pattern to verify graphics mode
draw_test_pattern:
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0xA000
    mov es, ax
    
    ; Draw horizontal color bars
    mov dx, 0              ; Y coordinate
    
.draw_bars:
    mov cx, 0              ; X coordinate
    mov di, dx
    imul di, 320           ; Calculate row offset
    
.draw_line:
    mov ax, cx
    shr ax, 5              ; Divide by 32 for color selection
    and ax, 0x0F           ; Keep only lower 4 bits
    add ax, 1              ; Avoid black (color 0)
    
    mov es:[di], al        ; Set pixel color
    inc di
    inc cx
    cmp cx, 320
    jl .draw_line
    
    inc dx
    cmp dx, 200
    jl .draw_bars
    
    ; Draw border rectangle
    call draw_border
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Draw border rectangle
draw_border:
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0xA000
    mov es, ax
    mov al, 0x0F           ; White color
    
    ; Top border
    mov di, 0
    mov cx, 320
.top_border:
    mov es:[di], al
    inc di
    loop .top_border
    
    ; Bottom border
    mov di, 63680          ; (200-1) * 320
    mov cx, 320
.bottom_border:
    mov es:[di], al
    inc di
    loop .bottom_border
    
    ; Left and right borders
    mov dx, 1              ; Start from second row
.side_borders:
    mov di, dx
    imul di, 320           ; Left border
    mov es:[di], al
    
    add di, 319            ; Right border
    mov es:[di], al
    
    inc dx
    cmp dx, 199
    jl .side_borders
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print text in graphics mode (simple bitmap font)
print_graphics_text:
    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push di
    
    mov ax, 0xA000
    mov es, ax
    mov dx, 10             ; Y position for text
    mov bx, 10             ; X position for text
    
.text_loop:
    lodsb                  ; Load character
    cmp al, 0
    je .text_done
    
    cmp al, 13             ; Carriage return
    je .next_line
    
    cmp al, 10             ; Line feed
    je .next_line
    
    ; Draw character (simple 8x8 bitmap)
    call draw_character
    add bx, 8              ; Move to next character position
    
    cmp bx, 312            ; Check if near right edge
    jl .text_loop
    
.next_line:
    mov bx, 10             ; Reset X position
    add dx, 10             ; Move to next line
    jmp .text_loop
    
.text_done:
    pop di
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Draw a single character at position BX,DX
draw_character:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    ; Simple character rendering - draw a white rectangle for any character
    mov si, dx
    imul si, 320           ; Calculate row offset
    add si, bx             ; Add column offset
    
    mov cx, 8              ; Character height
    
.char_row:
    push cx
    push si
    mov cx, 6              ; Character width
    mov al, 0x0F           ; White color
    
.char_pixel:
    mov es:[si], al
    inc si
    loop .char_pixel
    
    pop si
    add si, 320            ; Move to next row
    pop cx
    loop .char_row
    
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Wait for a key press
wait_for_key:
    push ax
    
    mov ah, 0x00           ; Wait for keypress
    int 0x16               ; BIOS keyboard interrupt
    
    pop ax
    ret

; VGA module messages
vga_success_msg db 'VGA Graphics Mode Initialized Successfully', 13, 10, 0
vga_complete_msg db 'VGA initialization complete. Returning to text mode.', 13, 10, 0
vga_error_msg db 'ERROR: Failed to initialize VGA graphics mode.', 13, 10, 0
press_key_msg db 'Press any key to continue...', 13, 10, 0

; VGA module variables
original_video_mode db 0
