[BITS 16]
[ORG 0x7C00]

%include "constants.inc"

start:
    ; Segmentleri temizle
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Boot mesajı
    mov si, boot_msg
    call print_string
    
    ; Disk okuma - disk.bin yükle
    mov ah, 0x02        ; Disk okuma fonksiyonu
    mov al, DISK_SECTORS ; Kaç sektör okunacak
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2 (1 = boot sector)
    mov dh, 0           ; Head 0
    mov dl, 0x80        ; Drive 0 (ilk hard disk)
    mov bx, DISK_LOAD_ADDR ; Bellek adresi
    
    int 0x13            ; BIOS disk servisi
    jc disk_error       ; Hata kontrolü
    
    ; Disk yükleme başarılı mesajı
    mov si, disk_loaded_msg
    call print_string
    
    ; 32-bit protected mode'a geç
    cli
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    jmp CODE_SEG:init_pm

disk_error:
    mov si, disk_error_msg
    call print_string
    hlt

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; 32-bit protected mode başlangıcı
[BITS 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov ebp, 0x90000
    mov esp, ebp
    
    ; disk.bin'i çağır
    jmp DISK_LOAD_ADDR

; GDT (Global Descriptor Table)
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

gdt_code:
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0

gdt_data:
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Mesajlar
boot_msg db 'LAMAX64 Boot Loader v1.0', 13, 10, 'Loading system...', 13, 10, 0
disk_loaded_msg db 'Disk loader initialized.', 13, 10, 0
disk_error_msg db 'Disk read error!', 13, 10, 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
