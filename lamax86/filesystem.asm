; File System Access Module
; Provides basic file system operations to locate and load files

; Load disk.bin from the file system
load_disk_bin:
    push ax
    push bx
    push cx
    push dx
    push si
    push es
    
    mov si, searching_disk_bin_msg
    call print_string
    
    ; Set up buffer in conventional memory for disk.bin
    mov ax, DISK_BIN_SEGMENT
    mov es, ax
    xor bx, bx             ; ES:BX points to load location
    
    ; Try to load disk.bin from different possible locations
    ; First try: Root directory of first hard disk
    mov dl, 0x80           ; First hard disk
    call load_from_root_directory
    
    cmp al, 1              ; Check if successful
    je .disk_bin_loaded
    
    ; Second try: Boot partition
    call load_from_boot_partition
    
    cmp al, 1
    je .disk_bin_loaded
    
    ; Third try: Floppy disk
    mov dl, 0x00           ; First floppy drive
    call load_from_floppy
    
    cmp al, 1
    je .disk_bin_loaded
    
    ; Failed to find disk.bin
    mov si, disk_bin_not_found_msg
    call print_string
    jmp .error
    
.disk_bin_loaded:
    mov si, disk_bin_loaded_msg
    call print_string
    
    ; Validate disk.bin signature
    mov si, DISK_BIN_SEGMENT * 16
    mov cx, 512            ; Check at least first sector
    call validate_file_signature
    
    cmp al, 1
    jne .invalid_signature
    
    mov si, disk_bin_valid_msg
    call print_string
    jmp .done
    
.invalid_signature:
    mov si, disk_bin_invalid_msg
    call print_string
    jmp .error
    
.error:
    mov byte [disk_bin_loaded_flag], 0
    jmp .exit
    
.done:
    mov byte [disk_bin_loaded_flag], 1
    
.exit:
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Load from root directory (simplified FAT12/16 approach)
load_from_root_directory:
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    ; Read boot sector to get file system information
    mov ah, 0x02           ; Read sectors
    mov al, 0x01           ; One sector
    mov ch, 0x00           ; Cylinder 0
    mov cl, 0x01           ; Sector 1
    mov dh, 0x00           ; Head 0
    ; DL already contains drive number
    mov bx, 0x0500         ; Load to 0x0500
    int 0x13
    
    jc .load_failed        ; If carry set, read failed
    
    ; Simple search for disk.bin in directory entries
    ; This is a simplified approach - real FAT parsing would be more complex
    mov si, 0x0500         ; Point to loaded sector
    add si, 0x2B           ; Skip to volume label area
    
    ; Look for our file in a simple directory structure
    ; For demo purposes, assume disk.bin is at a known location
    mov ah, 0x02           ; Read sectors
    mov al, 0x08           ; Read 8 sectors (4KB)
    mov ch, 0x00           ; Cylinder 0
    mov cl, 0x02           ; Start from sector 2
    mov dh, 0x00           ; Head 0
    mov bx, 0x0000         ; Load to ES:BX
    int 0x13
    
    jc .load_failed
    
    mov al, 1              ; Success
    jmp .done
    
.load_failed:
    mov al, 0              ; Failure
    
.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Load from boot partition
load_from_boot_partition:
    push bx
    push cx
    push dx
    
    ; Try to read from partition table
    mov ah, 0x02           ; Read sectors
    mov al, 0x08           ; Read multiple sectors
    mov ch, 0x00           ; Cylinder 0
    mov cl, 0x02           ; Sector 2 (after MBR)
    mov dh, 0x00           ; Head 0
    mov bx, 0x0000         ; Load to ES:BX
    int 0x13
    
    jc .partition_failed
    
    mov al, 1              ; Assume success for demo
    jmp .partition_done
    
.partition_failed:
    mov al, 0
    
.partition_done:
    pop dx
    pop cx
    pop bx
    ret

; Load from floppy disk
load_from_floppy:
    push bx
    push cx
    push dx
    
    ; Reset floppy drive
    mov ah, 0x00
    ; DL contains drive number (0x00 for floppy)
    int 0x13
    
    ; Read from floppy
    mov ah, 0x02           ; Read sectors
    mov al, 0x06           ; Read 6 sectors (3KB)
    mov ch, 0x00           ; Cylinder 0
    mov cl, 0x02           ; Sector 2
    mov dh, 0x00           ; Head 0
    mov bx, 0x0000         ; Load to ES:BX
    int 0x13
    
    jc .floppy_failed
    
    mov al, 1              ; Success
    jmp .floppy_done
    
.floppy_failed:
    mov al, 0              ; Failure
    
.floppy_done:
    pop dx
    pop cx
    pop bx
    ret

; Read a specific sector from disk
read_sector:
    ; Input: DL = drive, CX = cylinder/sector, DH = head, ES:BX = buffer
    ; Output: AL = 1 if success, 0 if failure
    push dx
    
    mov ah, 0x02           ; Read sectors function
    mov al, 0x01           ; Read one sector
    int 0x13
    
    jc .read_failed
    mov al, 1              ; Success
    jmp .read_done
    
.read_failed:
    mov al, 0              ; Failure
    
.read_done:
    pop dx
    ret

; Create simple directory entry structure for file searching
find_file_in_directory:
    ; Input: SI = directory buffer, DI = filename to find
    ; Output: AL = 1 if found, BX = file location
    push cx
    push dx
    push si
    push di
    
    ; Simplified file search - in real implementation this would
    ; parse actual directory structures
    mov cx, 16             ; Check first 16 directory entries
    
.search_loop:
    push cx
    push si
    push di
    
    ; Compare filename (8 characters for simplicity)
    mov cx, 8
    repe cmpsb
    
    pop di
    pop si
    pop cx
    
    je .file_found         ; If strings match, file found
    
    add si, 32             ; Move to next directory entry (32 bytes each)
    loop .search_loop
    
    mov al, 0              ; File not found
    jmp .search_done
    
.file_found:
    mov al, 1              ; File found
    ; In real implementation, extract file cluster/sector info
    
.search_done:
    pop di
    pop si
    pop dx
    pop cx
    ret

; File system messages
searching_disk_bin_msg db 'Searching for disk.bin...', 13, 10, 0
disk_bin_loaded_msg db 'disk.bin loaded successfully.', 13, 10, 0
disk_bin_not_found_msg db 'ERROR: disk.bin not found!', 13, 10, 0
disk_bin_valid_msg db 'disk.bin signature validated.', 13, 10, 0
disk_bin_invalid_msg db 'ERROR: disk.bin has invalid signature!', 13, 10, 0

; File system variables
disk_bin_loaded_flag db 0
current_drive db 0x80
