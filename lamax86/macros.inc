; Assembly Macros
; Useful macros for common operations

; Print a string macro
%macro PRINT_STRING 1
    mov si, %1
    call print_string
%endmacro

; Print a hexadecimal value macro  
%macro PRINT_HEX 1
    mov ax, %1
    call print_hex
%endmacro

; Print a newline macro
%macro PRINT_NEWLINE 0
    mov si, newline
    call print_string
%endmacro

; Save all general-purpose registers
%macro SAVE_REGS 0
    push ax
    push bx
    push cx
    push dx
    push si
    push di
%endmacro

; Restore all general-purpose registers  
%macro RESTORE_REGS 0
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
%endmacro

; Save all registers including segments
%macro SAVE_ALL_REGS 0
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
%endmacro

; Restore all registers including segments
%macro RESTORE_ALL_REGS 0
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
%endmacro

; Set video mode macro
%macro SET_VIDEO_MODE 1
    mov ah, 0x00
    mov al, %1
    int 0x10
%endmacro

; Read sector macro
%macro READ_SECTOR 4
    ; %1 = drive, %2 = cylinder, %3 = head, %4 = sector
    mov dl, %1
    mov ch, %2
    mov dh, %3
    mov cl, %4
    mov ah, 0x02
    mov al, 0x01
    int 0x13
%endmacro

; Delay macro (simple loop-based delay)
%macro DELAY 1
    push cx
    mov cx, %1
%%delay_loop:
    nop
    loop %%delay_loop
    pop cx
%endmacro

; Check carry flag and jump if set
%macro JC_ERROR 1
    jc %1
%endmacro

; Compare and jump if equal macro
%macro CMP_JE 3
    cmp %1, %2
    je %3
%endmacro

; Compare and jump if not equal macro
%macro CMP_JNE 3
    cmp %1, %2
    jne %3
%endmacro

; Test bit and jump if set
%macro TEST_BIT_JNZ 3
    test %1, %2
    jnz %3
%endmacro

; Test bit and jump if clear
%macro TEST_BIT_JZ 3
    test %1, %2
    jz %3
%endmacro

; Set segment register macro
%macro SET_SEGMENT 2
    mov %1, %2
%endmacro

; Clear register macro
%macro CLEAR_REG 1
    xor %1, %1
%endmacro

; Increment with overflow check
%macro INC_CHECK_OVERFLOW 2
    inc %1
    cmp %1, %2
    jl %%no_overflow
    mov %1, 0
%%no_overflow:
%endmacro

; Decrement with underflow check  
%macro DEC_CHECK_UNDERFLOW 1
    cmp %1, 0
    je %%no_underflow
    dec %1
%%no_underflow:
%endmacro

; Multiply by power of 2 using shifts
%macro MUL_POW2 2
    shl %1, %2
%endmacro

; Divide by power of 2 using shifts
%macro DIV_POW2 2
    shr %1, %2
%endmacro

; Set flags based on comparison
%macro SET_FLAGS 2
    cmp %1, %2
%endmacro

; Jump to error handler with error code
%macro ERROR_EXIT 1
    mov al, %1
    jmp error_handler
%endmacro

; Validate pointer is not null
%macro VALIDATE_POINTER 2
    cmp %1, 0
    je %2
%endmacro

; Bounds check macro
%macro BOUNDS_CHECK 4
    ; %1 = value, %2 = min, %3 = max, %4 = error_label
    cmp %1, %2
    jl %4
    cmp %1, %3
    jg %4
%endmacro

; Align to boundary macro
%macro ALIGN_TO 1
    times ((%1) - ($ - $$) % (%1)) % (%1) db 0
%endmacro

; Define string with length prefix
%macro DEF_STRING 1
%%str_start:
    db %1, 0
%%str_len equ $ - %%str_start - 1
%endmacro

; Copy memory block macro
%macro COPY_MEMORY 3
    ; %1 = source, %2 = destination, %3 = count
    push si
    push di
    push cx
    mov si, %1
    mov di, %2
    mov cx, %3
    rep movsb
    pop cx
    pop di
    pop si
%endmacro

; Fill memory with value macro
%macro FILL_MEMORY 3
    ; %1 = destination, %2 = value, %3 = count
    push di
    push ax
    push cx
    mov di, %1
    mov al, %2
    mov cx, %3
    rep stosb
    pop cx
    pop ax
    pop di
%endmacro

; Convert number to string macro (simplified)
%macro NUM_TO_STR 2
    ; %1 = number, %2 = buffer
    push ax
    push bx
    push cx
    push dx
    mov ax, %1
    mov bx, %2
    call number_to_string
    pop dx
    pop cx
    pop bx
    pop ax
%endmacro
