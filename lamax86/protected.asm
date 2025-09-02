; Protected Mode Transition Module
; Handles the transition from Real Mode to Protected Mode

; Enter protected mode and transfer control to kernel
enter_protected_mode:
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Check if kernel is loaded
    cmp byte [kernel_loaded_flag], 1
    jne .no_kernel_error
    
    mov si, preparing_protected_mode_msg
    call print_string
    
    ; Disable interrupts
    cli
    
    ; Setup Global Descriptor Table (GDT)
    call setup_gdt
    
    ; Enable A20 line
    call enable_a20
    
    ; Load GDT register
    lgdt [gdt_descriptor]
    
    ; Switch to protected mode
    mov eax, cr0
    or eax, 0x00000001     ; Set PE (Protection Enable) bit
    mov cr0, eax
    
    ; Flush prefetch queue and reload CS
    jmp CODE_SEG:protected_mode_entry
    
.no_kernel_error:
    mov si, no_kernel_protected_msg
    call print_string
    jmp .exit
    
.exit:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Protected mode entry point (32-bit code)
[BITS 32]
protected_mode_entry:
    ; Setup data segments
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Setup stack
    mov esp, 0x90000       ; Set stack pointer
    
    ; Clear screen in protected mode
    call clear_screen_32
    
    ; Display protected mode message
    mov esi, protected_mode_success_msg_32
    call print_string_32
    
    ; Transfer control to kernel
    jmp execute_kernel_32

; Setup Global Descriptor Table
[BITS 16]
setup_gdt:
    push ax
    push bx
    push cx
    push si
    push di
    
    mov si, setting_up_gdt_msg
    call print_string
    
    ; GDT is already defined in data section
    ; Just verify it's set up correctly
    
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; Enable A20 line for access to extended memory
enable_a20:
    push ax
    push cx
    
    mov si, enabling_a20_msg
    call print_string
    
    ; Method 1: Try keyboard controller
    call enable_a20_keyboard
    call test_a20
    cmp ax, 1
    je .a20_enabled
    
    ; Method 2: Try fast A20
    call enable_a20_fast
    call test_a20
    cmp ax, 1
    je .a20_enabled
    
    ; Method 3: Try BIOS
    call enable_a20_bios
    call test_a20
    cmp ax, 1
    je .a20_enabled
    
    ; A20 enable failed
    mov si, a20_failed_msg
    call print_string
    jmp .done
    
.a20_enabled:
    mov si, a20_enabled_msg
    call print_string
    
.done:
    pop cx
    pop ax
    ret

; Enable A20 via keyboard controller
enable_a20_keyboard:
    push ax
    
    ; Disable keyboard
    call wait_8042_command
    mov al, 0xAD
    out 0x64, al
    
    ; Read from input
    call wait_8042_command
    mov al, 0xD0
    out 0x64, al
    
    call wait_8042_data
    in al, 0x60
    push ax
    
    ; Write to output
    call wait_8042_command
    mov al, 0xD1
    out 0x64, al
    
    call wait_8042_command
    pop ax
    or al, 2               ; Set A20 bit
    out 0x60, al
    
    ; Enable keyboard
    call wait_8042_command
    mov al, 0xAE
    out 0x64, al
    
    call wait_8042_command
    
    pop ax
    ret

wait_8042_command:
    push ax
.loop:
    in al, 0x64
    test al, 2
    jnz .loop
    pop ax
    ret

wait_8042_data:
    push ax
.loop:
    in al, 0x64
    test al, 1
    jz .loop
    pop ax
    ret

; Enable A20 via fast method
enable_a20_fast:
    push ax
    
    in al, 0x92
    test al, 2
    jnz .done
    or al, 2
    and al, 0xFE
    out 0x92, al
    
.done:
    pop ax
    ret

; Enable A20 via BIOS
enable_a20_bios:
    push ax
    push bx
    
    mov ax, 0x2401
    int 0x15
    
    pop bx
    pop ax
    ret

; Test if A20 line is enabled
test_a20:
    push ds
    push es
    push di
    push si
    
    xor ax, ax
    mov es, ax
    not ax
    mov ds, ax
    
    mov di, 0x0500
    mov si, 0x0510
    
    mov al, [es:di]
    push ax
    
    mov al, [ds:si]
    push ax
    
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF
    
    cmp byte [es:di], 0xFF
    
    pop ax
    mov [ds:si], al
    
    pop ax
    mov [es:di], al
    
    mov ax, 0
    je .done
    
    mov ax, 1
    
.done:
    pop si
    pop di
    pop es
    pop ds
    ret

; 32-bit protected mode functions
[BITS 32]

; Clear screen in 32-bit mode
clear_screen_32:
    push eax
    push ecx
    push edi
    
    mov edi, 0xB8000       ; VGA text buffer
    mov eax, 0x07200720    ; Space character with white on black
    mov ecx, 2000          ; 80x25 screen
    rep stosd
    
    pop edi
    pop ecx
    pop eax
    ret

; Print string in 32-bit mode
print_string_32:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov edi, 0xB8000       ; VGA text buffer
    mov ah, 0x07           ; White on black attribute
    
.loop:
    lodsb
    cmp al, 0
    je .done
    
    stosw                  ; Store character and attribute
    jmp .loop
    
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Execute kernel in protected mode
execute_kernel_32:
    ; Final transfer to loaded kernel
    ; Jump to kernel entry point
    mov eax, KERNEL_SEGMENT * 16  ; Convert segment to linear address
    jmp eax                       ; Jump to kernel

[BITS 16]  ; Return to 16-bit for data definitions

; Global Descriptor Table
gdt_start:
    ; Null descriptor
    dd 0x0
    dd 0x0
    
    ; Code segment descriptor
gdt_code:
    dw 0xFFFF              ; Limit (low)
    dw 0x0000              ; Base (low)
    db 0x00                ; Base (middle)
    db 10011010b           ; Access byte
    db 11001111b           ; Flags, Limit (high)
    db 0x00                ; Base (high)
    
    ; Data segment descriptor  
gdt_data:
    dw 0xFFFF              ; Limit (low)
    dw 0x0000              ; Base (low)
    db 0x00                ; Base (middle)
    db 10010010b           ; Access byte
    db 11001111b           ; Flags, Limit (high)
    db 0x00                ; Base (high)
    
gdt_end:

; GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_start - 1    ; Size
    dd gdt_start                  ; Offset

; Protected mode messages (16-bit)
preparing_protected_mode_msg db 'Preparing to enter Protected Mode...', 13, 10, 0
setting_up_gdt_msg db 'Setting up Global Descriptor Table...', 13, 10, 0
enabling_a20_msg db 'Enabling A20 line...', 13, 10, 0
a20_enabled_msg db 'A20 line enabled successfully.', 13, 10, 0
a20_failed_msg db 'WARNING: Failed to enable A20 line.', 13, 10, 0
no_kernel_protected_msg db 'ERROR: Cannot enter Protected Mode without kernel.', 13, 10, 0

; 32-bit messages (null-terminated for 32-bit code)
protected_mode_success_msg_32 db 'Protected Mode entered successfully. Transferring to kernel...', 0
