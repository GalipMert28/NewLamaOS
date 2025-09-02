; Çalışan CLI Kernel - Basit ve Etkili
[BITS 32]
[ORG 0x20000]

; Kernel imzası
kernel_signature dd 0x4B52444C    ; 'KRDL'
kernel_size dd kernel_end - kernel_start
entry_point dd kernel_start
reserved dd 0x90909090

kernel_start:
    ; Segmentleri ayarla
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000

    ; Direkt CLI başlat
    call init_cli
    
    ; Ana komut döngüsü
main_loop:
    call show_prompt
    call get_command
    call exec_command
    jmp main_loop

; CLI başlatma
init_cli:
    ; Ekranı tamamen temizle
    mov edi, 0xB8000
    mov eax, 0x0F200F20    ; Beyaz üzerine siyah
    mov ecx, 2000
    rep stosd
    
    ; Banner göster
    mov esi, banner
    call print_str
    
    ret

; String yazdır
print_str:
    push edi
    push eax
    
    mov edi, 0xB8000
    mov ah, 0x0F
    
.loop:
    lodsb
    test al, al
    jz .done
    
    cmp al, 10    ; newline
    je .newline
    
    stosw
    jmp .loop
    
.newline:
    ; Next line hesaplama
    push eax
    push edx
    mov eax, edi
    sub eax, 0xB8000
    mov edx, 160
    div edx
    inc eax
    mul edx
    add eax, 0xB8000
    mov edi, eax
    pop edx
    pop eax
    jmp .loop
    
.done:
    ; Cursor pozisyonunu kaydet
    mov [cursor_pos], edi
    pop eax
    pop edi
    ret

; Prompt göster
show_prompt:
    mov esi, prompt
    mov edi, [cursor_pos]
    mov ah, 0x0F
    
.loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .loop
    
.done:
    mov [cursor_pos], edi
    ret

; Komut al
get_command:
    push ebx
    push ecx
    
    mov ebx, cmd_buffer
    xor ecx, ecx
    
.get_key:
    ; Klavye bekle
    in al, 0x64
    test al, 1
    jz .get_key
    
    in al, 0x60
    
    ; Sadece press events
    test al, 0x80
    jnz .get_key
    
    ; Enter (0x1C)
    cmp al, 0x1C
    je .enter
    
    ; Backspace (0x0E)
    cmp al, 0x0E
    je .backspace
    
    ; Character lookup
    movzx edx, al
    mov al, [key_map + edx]
    test al, al
    jz .get_key
    
    ; Buffer'a ekle
    cmp ecx, 79
    jge .get_key
    
    mov [ebx + ecx], al
    inc ecx
    
    ; Ekranda göster
    mov edi, [cursor_pos]
    mov ah, 0x0F
    stosw
    mov [cursor_pos], edi
    
    jmp .get_key
    
.backspace:
    test ecx, ecx
    jz .get_key
    
    dec ecx
    sub dword [cursor_pos], 2
    mov edi, [cursor_pos]
    mov ax, 0x0F20
    mov [edi], ax
    
    jmp .get_key
    
.enter:
    mov byte [ebx + ecx], 0
    
    ; Newline
    mov esi, newline
    call print_str
    
    pop ecx
    pop ebx
    ret

; Komut çalıştır
exec_command:
    mov esi, cmd_buffer
    
    ; Boş mu?
    cmp byte [esi], 0
    je .done
    
    ; help?
    mov edi, str_help
    call strcmp
    je .do_help
    
    ; version?
    mov edi, str_version
    call strcmp
    je .do_version
    
    ; clear?
    mov edi, str_clear
    call strcmp
    je .do_clear
    
    ; stats?
    mov edi, str_stats
    call strcmp
    je .do_stats
    
    ; ls?
    mov edi, str_ls
    call strcmp
    je .do_ls
    
    ; Bilinmeyen
    mov esi, msg_unknown
    call print_str
    ret
    
.do_help:
    mov esi, msg_help
    call print_str
    ret
    
.do_version:
    mov esi, msg_version
    call print_str
    ret
    
.do_clear:
    call init_cli
    ret
    
.do_stats:
    mov esi, msg_stats
    call print_str
    ret
    
.do_ls:
    mov esi, msg_ls
    call print_str
    ret
    
.done:
    ret

; String karşılaştır (ZF set if equal)
strcmp:
    push esi
    push edi
    
.loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .not_eq
    
    test al, al
    jz .equal
    
    inc esi
    inc edi
    jmp .loop
    
.equal:
    pop edi
    pop esi
    ; ZF = 1 (equal)
    cmp al, al
    ret
    
.not_eq:
    pop edi
    pop esi
    ; ZF = 0 (not equal)
    cmp al, bl
    ret

; Değişkenler
cursor_pos dd 0xB8000 + 160*12  ; 12. satır
cmd_buffer times 80 db 0

; Klavye haritası (scan code -> ASCII)
key_map:
    times 16 db 0
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 0, 0, 0, 0, 'a', 's'
    db 'd', 'f', 'g', 'h', 'j', 'k', 'l', 0, 0, 0, 0, 0, 'z', 'x', 'c', 'v'
    db 'b', 'n', 'm', 0, 0, 0, 0, 0, 0, ' ', 0, 0, 0, 0, 0, 0
    times 192 db 0

; Komut stringleri
str_help db 'help', 0
str_version db 'version', 0
str_clear db 'clear', 0
str_stats db 'stats', 0
str_ls db 'ls', 0

; Mesajlar
banner db '======================================', 10
       db '       KRDL CLI Kernel v1.0          ', 10
       db '======================================', 10
       db 'Assembly Kernel - CLI Tamamen Aktif!', 10
       db 'Komutlar: help, version, clear, stats, ls', 10, 10, 0

prompt db 'KRDL> ', 0
newline db 10, 0

msg_help db 'Mevcut Komutlar:', 10
         db '  help - Bu yardim', 10
         db '  version - Sistem versiyonu', 10
         db '  clear - Ekrani temizle', 10
         db '  stats - Sistem bilgisi', 10
         db '  ls - Dosya listesi', 10, 10, 0

msg_version db 'KRDL CLI Kernel v1.0', 10
            db 'Assembly + Protected Mode', 10
            db 'Tam CLI destegi aktif!', 10, 10, 0

msg_stats db 'Sistem Durumu:', 10
          db '  CPU: x86 32-bit Protected Mode', 10
          db '  Bellek: 16MB aktif', 10
          db '  Kernel: CLI Kernel 8KB', 10, 10, 0

msg_ls db 'Dosya Sistemi:', 10
       db '  boot.asm - Bootloader kaynak', 10
       db '  kernel.bin - CLI kernel binary', 10
       db '  disk.bin - Disk image dosyasi', 10, 10, 0

msg_unknown db 'Bilinmeyen komut! help yazin.', 10, 10, 0

kernel_end:

; Padding
times 8192-($-$$) db 0