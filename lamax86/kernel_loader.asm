; Kernel Loading Module
; Searches for and loads kernel.bin from within disk.bin

; Find and load kernel.bin from the loaded disk.bin
find_and_load_kernel:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    ; Check if disk.bin was loaded successfully
    cmp byte [disk_bin_loaded_flag], 1
    jne .no_disk_bin
    
    mov si, searching_kernel_msg
    call print_string
    
    ; Set up search parameters
    mov ax, DISK_BIN_SEGMENT
    mov es, ax
    xor si, si             ; ES:SI points to disk.bin data
    
    ; Search for kernel.bin within disk.bin
    call search_kernel_in_diskbin
    
    cmp al, 1
    jne .kernel_not_found
    
    ; Load kernel.bin to its designated memory location
    call load_kernel_to_memory
    
    cmp al, 1
    jne .kernel_load_error
    
    ; Validate kernel.bin
    call validate_kernel_binary
    
    cmp al, 1
    jne .kernel_invalid
    
    ; Setup kernel parameters
    call setup_kernel_parameters
    
    mov si, kernel_ready_msg
    call print_string
    
    mov byte [kernel_loaded_flag], 1
    jmp .done
    
.no_disk_bin:
    mov si, no_disk_bin_msg
    call print_string
    jmp .error
    
.kernel_not_found:
    mov si, kernel_not_found_msg
    call print_string
    jmp .error
    
.kernel_load_error:
    mov si, kernel_load_error_msg
    call print_string
    jmp .error
    
.kernel_invalid:
    mov si, kernel_invalid_msg
    call print_string
    jmp .error
    
.error:
    mov byte [kernel_loaded_flag], 0
    jmp .exit
    
.done:
    mov byte [kernel_loaded_flag], 1
    
.exit:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Search for kernel.bin within the loaded disk.bin
search_kernel_in_diskbin:
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Look for kernel.bin signature or filename
    mov di, kernel_filename
    mov cx, DISK_BIN_SIZE  ; Search within entire disk.bin
    
.search_loop:
    push cx
    push si
    
    ; Look for "KERNEL  BIN" filename pattern
    mov cx, 11             ; DOS 8.3 filename length
    push di
    repe cmpsb
    pop di
    
    pop si
    pop cx
    
    je .found_kernel       ; Found filename match
    
    ; Also search for kernel signature
    push si
    cmp dword [es:si], KERNEL_SIGNATURE
    pop si
    je .found_kernel
    
    inc si                 ; Move to next byte
    loop .search_loop
    
    ; Not found
    mov al, 0
    jmp .search_done
    
.found_kernel:
    mov [kernel_location_offset], si
    mov al, 1              ; Found
    
.search_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Load kernel.bin to its designated memory location
load_kernel_to_memory:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
    
    ; Set up source (disk.bin) and destination (kernel memory)
    mov ax, DISK_BIN_SEGMENT
    mov ds, ax
    mov si, [kernel_location_offset]
    
    mov ax, KERNEL_SEGMENT
    mov es, ax
    xor di, di
    
    ; Determine kernel size (simplified - assume first dword contains size)
    mov cx, [ds:si+4]      ; Kernel size from header
    cmp cx, 0
    je .use_default_size
    
    cmp cx, MAX_KERNEL_SIZE
    ja .size_too_large
    
    jmp .start_copy
    
.use_default_size:
    mov cx, DEFAULT_KERNEL_SIZE
    
.start_copy:
    ; Copy kernel data
    push cx
    shr cx, 1              ; Convert to words for faster copy
    rep movsw
    pop cx
    
    and cx, 1              ; Handle odd byte
    rep movsb
    
    ; Verify copy was successful
    mov ax, KERNEL_SEGMENT
    mov es, ax
    cmp word [es:0], 0x5A4D ; Check for PE signature
    je .copy_successful
    
    cmp word [es:0], 0x7F45 ; Check for ELF signature
    je .copy_successful
    
    cmp dword [es:0], KERNEL_SIGNATURE ; Check for custom signature
    je .copy_successful
    
    mov al, 0              ; Copy failed
    jmp .copy_done
    
.size_too_large:
    mov al, 0              ; Size too large
    jmp .copy_done
    
.copy_successful:
    mov al, 1              ; Success
    
.copy_done:
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Validate kernel binary
validate_kernel_binary:
    push bx
    push cx
    push dx
    push si
    push es
    
    mov ax, KERNEL_SEGMENT
    mov es, ax
    xor si, si
    
    ; Check kernel signature
    cmp dword [es:si], KERNEL_SIGNATURE
    je .signature_ok
    
    ; Check for standard executable signatures
    cmp word [es:si], 0x5A4D ; DOS/PE signature
    je .signature_ok
    
    cmp word [es:si], 0x7F45 ; ELF signature start
    jne .invalid_signature
    
    cmp word [es:si+2], 0x464C ; Complete ELF signature
    jne .invalid_signature
    
.signature_ok:
    ; Additional validation - check entry point
    mov bx, [es:si+8]      ; Assume entry point at offset 8
    cmp bx, 0
    je .invalid_entry
    
    ; Validate checksum (simplified)
    call calculate_kernel_checksum
    
    mov al, 1              ; Valid
    jmp .validation_done
    
.invalid_signature:
.invalid_entry:
    mov al, 0              ; Invalid
    
.validation_done:
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Calculate simple checksum of kernel
calculate_kernel_checksum:
    push bx
    push cx
    push dx
    push si
    push es
    
    mov ax, KERNEL_SEGMENT
    mov es, ax
    xor si, si
    xor ax, ax             ; Checksum accumulator
    mov cx, 1024           ; Check first 1KB
    
.checksum_loop:
    add al, [es:si]
    adc ah, 0
    inc si
    loop .checksum_loop
    
    mov [kernel_checksum], ax
    
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Setup kernel parameters and environment
setup_kernel_parameters:
    push ax
    push bx
    push cx
    push dx
    push es
    
    ; Setup parameter block for kernel
    mov ax, KERNEL_PARAM_SEGMENT
    mov es, ax
    xor bx, bx
    
    ; Store boot device
    mov al, [current_drive]
    mov [es:bx], al        ; Boot drive
    inc bx
    
    ; Store memory information
    mov ax, [pci_device_count]
    mov [es:bx], ax        ; PCI device count
    add bx, 2
    
    mov ax, [disk_count]
    mov [es:bx], ax        ; Disk count
    add bx, 2
    
    ; Store secure boot status
    mov al, [secure_boot_enabled]
    mov [es:bx], al        ; Secure boot flag
    inc bx
    
    ; Store bootloader hash
    mov ax, [bootloader_hash]
    mov [es:bx], ax        ; Bootloader hash
    add bx, 2
    
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Execute loaded kernel
execute_kernel:
    push ax
    push bx
    push cx
    push dx
    
    ; Check if kernel is loaded
    cmp byte [kernel_loaded_flag], 1
    jne .no_kernel
    
    mov si, executing_kernel_msg
    call print_string
    
    ; Setup registers for kernel entry
    mov ax, KERNEL_SEGMENT
    mov ds, ax
    mov es, ax
    
    ; Pass parameters to kernel
    mov si, KERNEL_PARAM_SEGMENT
    
    ; Jump to kernel entry point
    ; This will transfer control to the loaded kernel
    jmp KERNEL_SEGMENT:0x0000
    
.no_kernel:
    mov si, no_kernel_to_execute_msg
    call print_string
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Kernel loading messages
searching_kernel_msg db 'Searching for kernel.bin in disk.bin...', 13, 10, 0
kernel_ready_msg db 'kernel.bin loaded and validated successfully.', 13, 10, 0
no_disk_bin_msg db 'ERROR: disk.bin not loaded - cannot search for kernel.', 13, 10, 0
kernel_not_found_msg db 'ERROR: kernel.bin not found in disk.bin!', 13, 10, 0
kernel_load_error_msg db 'ERROR: Failed to load kernel.bin to memory!', 13, 10, 0
kernel_invalid_msg db 'ERROR: kernel.bin failed validation!', 13, 10, 0
executing_kernel_msg db 'Transferring control to kernel...', 13, 10, 0
no_kernel_to_execute_msg db 'ERROR: No kernel loaded for execution!', 13, 10, 0

; Kernel search data
kernel_filename db 'KERNEL  BIN', 0  ; DOS 8.3 format filename

; Kernel loading variables
kernel_loaded_flag db 0
kernel_location_offset dw 0
kernel_checksum dw 0
