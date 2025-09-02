; Hardware Detection Module
; Provides PCI scanning and INT13H disk enumeration

; Initialize hardware detection systems
hardware_init:
    push ax
    push bx
    push cx
    push dx
    
    ; Initialize hardware detection variables
    mov word [pci_device_count], 0
    mov word [disk_count], 0
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; PCI Bus Scanning
pci_scan:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, pci_start_msg
    call print_string
    
    ; Check if PCI BIOS is present
    mov ah, 0xB1           ; PCI BIOS function
    mov al, 0x01           ; PCI BIOS present?
    int 0x1A               ; PCI BIOS interrupt
    
    cmp ah, 0x00           ; Check if PCI supported
    jne .no_pci
    
    ; Scan PCI bus 0
    mov cx, 0x0000         ; Start at bus 0, device 0, function 0
    
.scan_loop:
    push cx
    
    ; Read PCI configuration space
    mov ah, 0xB1           ; PCI BIOS function
    mov al, 0x08           ; Read configuration word
    mov di, 0x00           ; Register offset (Vendor ID)
    int 0x1A
    
    cmp cx, 0xFFFF         ; Check if device exists
    je .next_device
    
    ; Device found - display information
    push cx
    mov si, pci_device_msg
    call print_string
    
    ; Print bus number
    pop ax                 ; Get back bus/dev/func
    push ax
    shr ax, 8              ; Get bus number
    call print_hex
    
    mov si, pci_separator
    call print_string
    
    ; Print device number  
    pop ax
    push ax
    and ax, 0x00F8         ; Mask device bits
    shr ax, 3
    call print_hex
    
    mov si, pci_separator
    call print_string
    
    ; Print function number
    pop ax
    and ax, 0x0007         ; Mask function bits
    call print_hex
    
    mov si, pci_vendor_msg
    call print_string
    mov ax, cx             ; Vendor ID
    call print_hex
    
    ; Read Device ID
    mov ah, 0xB1
    mov al, 0x08
    mov di, 0x02           ; Device ID offset
    int 0x1A
    
    mov si, pci_device_id_msg
    call print_string
    mov ax, cx
    call print_hex
    
    mov si, newline
    call print_string
    
    ; Increment device count
    inc word [pci_device_count]
    
.next_device:
    pop cx
    inc cx                 ; Next device/function
    cmp cx, 0x0800         ; Scanned all devices on bus 0?
    jl .scan_loop
    
    ; Display summary
    mov si, pci_summary_msg
    call print_string
    mov ax, [pci_device_count]
    call print_hex
    mov si, pci_devices_found
    call print_string
    
    jmp .done
    
.no_pci:
    mov si, no_pci_msg
    call print_string
    
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; INT13H Disk Scanning
int13h_scan:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, disk_start_msg
    call print_string
    
    ; Start with drive 0x80 (first hard disk)
    mov dl, 0x80
    mov word [disk_count], 0
    
.scan_drives:
    ; Get drive parameters
    mov ah, 0x08           ; Get drive parameters
    mov di, 0x0000         ; ES:DI = 0000:0000
    int 0x13
    
    jc .next_drive         ; If carry set, drive doesn't exist
    
    ; Drive exists - display information
    mov si, disk_found_msg
    call print_string
    
    ; Print drive number
    mov al, dl
    call print_hex
    
    mov si, disk_heads_msg
    call print_string
    mov al, dh             ; Max head number
    inc al                 ; Convert to count
    xor ah, ah
    call print_hex
    
    mov si, disk_sectors_msg
    call print_string
    and cx, 0x003F         ; Mask sectors per track
    mov ax, cx
    call print_hex
    
    mov si, disk_cylinders_msg
    call print_string
    mov ax, cx
    shr ax, 6              ; Get cylinder bits from CX
    mov al, ch             ; Low 8 bits of cylinder
    call print_hex
    
    mov si, newline
    call print_string
    
    inc word [disk_count]
    
.next_drive:
    inc dl                 ; Next drive
    cmp dl, 0x84           ; Check up to 4 drives
    jl .scan_drives
    
    ; Scan floppy drives
    mov dl, 0x00           ; Start with floppy drive A:
    
.scan_floppies:
    mov ah, 0x08           ; Get drive parameters
    int 0x13
    
    jc .next_floppy        ; Drive doesn't exist
    
    mov si, floppy_found_msg
    call print_string
    mov al, dl
    call print_hex
    mov si, newline
    call print_string
    
    inc word [disk_count]
    
.next_floppy:
    inc dl
    cmp dl, 0x02           ; Check drives A: and B:
    jl .scan_floppies
    
    ; Display summary
    mov si, disk_summary_msg
    call print_string
    mov ax, [disk_count]
    call print_hex
    mov si, disks_found_msg
    call print_string
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Hardware detection messages
pci_start_msg db 'Starting PCI bus scan...', 13, 10, 0
pci_device_msg db 'PCI Device: ', 0
pci_separator db ':', 0
pci_vendor_msg db ' Vendor: 0x', 0
pci_device_id_msg db ' Device: 0x', 0
pci_summary_msg db 'PCI scan complete. Found 0x', 0
pci_devices_found db ' devices.', 13, 10, 0
no_pci_msg db 'PCI BIOS not detected.', 13, 10, 0

disk_start_msg db 'Starting disk enumeration...', 13, 10, 0
disk_found_msg db 'Hard Disk 0x', 0
disk_heads_msg db ' Heads: 0x', 0
disk_sectors_msg db ' Sectors: 0x', 0
disk_cylinders_msg db ' Cylinders: 0x', 0
floppy_found_msg db 'Floppy Drive 0x', 0
disk_summary_msg db 'Disk scan complete. Found 0x', 0
disks_found_msg db ' drives.', 13, 10, 0
newline db 13, 10, 0

; Hardware detection variables
pci_device_count dw 0
disk_count dw 0
