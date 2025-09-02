; Minimal Assembly Bootloader - Tüm özellikler
[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov si, m1
    call p

    ; PCI + Disk tarama
    mov ah, 0xB1
    mov al, 0x01
    int 0x1A
    cmp ah, 0x00
    jne .nopci
    mov si, m2
    call p
.nopci:
    
    ; Disk kontrol
    mov dl, 0x80
    mov ah, 0x08
    int 0x13
    jc .nodisk
    mov si, m3
    call p
.nodisk:

    ; VGA test
    mov ah, 0x00
    mov al, 0x13
    int 0x10
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov al, 1
    mov cx, 320
    rep stosb
    
    mov cx, 0x4000
.w: nop
    loop .w
    
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    mov si, m4
    call p

    ; Secure boot (imza kontrolü)
    mov ax, [0x7DFE]
    cmp ax, 0xAA55
    jne .secfail
    mov si, m5
    call p
    jmp .secok
.secfail:
    mov si, m6
    call p
.secok:

    ; disk.bin yükle
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    mov dl, 0x80
    mov ah, 0x02
    mov al, 0x04
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    int 0x13
    jc .lfail
    
    ; kernel.bin ara (KRDL imzası)
    mov cx, 0x800
    xor si, si
.srch:
    cmp dword [es:si], 0x4B52444C
    je .kfound
    inc si
    loop .srch
    mov si, m7
    call p
    jmp .nokernel
    
.kfound:
    ; kernel.bin kopyala
    push ds
    mov ax, 0x1000
    mov ds, ax
    mov ax, 0x2000
    mov es, ax
    xor di, di
    mov cx, 0x400
    rep movsb
    pop ds
    mov si, m8
    call p
    mov byte [kr], 1
    jmp .lok
    
.lfail:
    mov si, m9
    call p
.nokernel:
.lok:

    ; Protected mode
    mov si, m10
    call p
    
    ; A20
    in al, 0x92
    or al, 2
    out 0x92, al
    
    ; GDT
    lgdt [gdt_d]
    
    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:pm

p:  ; print fonksiyonu
    push ax
    push bx
.l: lodsb
    test al, al
    jz .e
    mov ah, 0x0E
    mov bh, 0x00
    int 0x10
    jmp .l
.e: pop bx
    pop ax
    ret

[BITS 32]
pm: ; Protected mode
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000
    
    ; Ekran temizle
    mov edi, 0xB8000
    mov eax, 0x0F200F20
    mov ecx, 500
    rep stosd
    
    ; Mesaj
    mov edi, 0xB8000
    mov esi, m32
    mov ah, 0x0F
.p32:
    lodsb
    test al, al
    jz .d32
    stosw
    jmp .p32
.d32:
    ; Kernel varsa çalıştır
    cmp byte [kr], 1
    jne .no_kernel
    
    ; Kernel başlatma mesajı
    mov edi, 0xB8000 + 160*2
    mov esi, kernel_msg
    mov ah, 0x0E
.print_kernel:
    lodsb
    test al, al
    jz .start_kernel
    stosw
    jmp .print_kernel
    
.start_kernel:
    ; Kernel'e atla
    jmp 0x20000
    
.no_kernel:
    mov edi, 0xB8000 + 160*2
    mov esi, no_kernel_msg
    mov ah, 0x0C
.print_error:
    lodsb
    test al, al
    jz .h
    stosw
    jmp .print_error
    
.h: hlt
    jmp .h

[BITS 16]
; GDT
gdt_s:
    dd 0, 0
    dd 0x0000FFFF, 0x00CF9A00
    dd 0x0000FFFF, 0x00CF9200
gdt_e:

gdt_d:
    dw gdt_e - gdt_s - 1
    dd gdt_s

kr db 0  ; kernel ready

; Mesajlar
m1 db 'Boot', 13, 10, 0
m2 db 'PCI+', 13, 10, 0
m3 db 'HDD+', 13, 10, 0
m4 db 'VGA+', 13, 10, 0
m5 db 'SEC+', 13, 10, 0
m6 db 'SEC-', 13, 10, 0
m7 db 'NoK', 13, 10, 0
m8 db 'Kernel+', 13, 10, 0
m9 db 'LoadErr', 13, 10, 0
m10 db '32bit', 13, 10, 0
m32 db 'Protected Mode OK', 0
kernel_msg db 'K+', 0
no_kernel_msg db 'K-', 0

times 510-($-$$) db 0
dw 0xAA55