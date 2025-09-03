/*
 * LAMAX64 OS - Shell
 * Version 1.0.0
 */

#include "system.h"

// VGA ekran tamponu
volatile char* vga_buffer = (volatile char*)0xB8000;
int cursor_x = 0, cursor_y = 0;

// String karşılaştırma
int strcmp(const char* str1, const char* str2) {
    while(*str1 && (*str1 == *str2)) {
        str1++;
        str2++;
    }
    return *str1 - *str2;
}

// String uzunluğu
int strlen(const char* str) {
    int len = 0;
    while(str[len]) len++;
    return len;
}

// String kopyalama
void strcpy(char* dest, const char* src) {
    while(*src) {
        *dest++ = *src++;
    }
    *dest = 0;
}

// Basit printf
void kprint(const char* str) {
    while(*str) {
        if(*str == '\n') {
            cursor_x = 0;
            cursor_y++;
        } else {
            int index = (cursor_y * 80 + cursor_x) * 2;
            vga_buffer[index] = *str;
            vga_buffer[index + 1] = 0x0F; // Parlak beyaz
            cursor_x++;
        }
        str++;
        
        if(cursor_x >= 80) {
            cursor_x = 0;
            cursor_y++;
        }
        
        if(cursor_y >= 25) {
            cursor_y = 24;
            // Ekranı kaydır
            for(int i = 0; i < 24 * 80; i++) {
                vga_buffer[i * 2] = vga_buffer[(i + 80) * 2];
                vga_buffer[i * 2 + 1] = vga_buffer[(i + 80) * 2 + 1];
            }
            for(int i = 24 * 80; i < 25 * 80; i++) {
                vga_buffer[i * 2] = ' ';
                vga_buffer[i * 2 + 1] = 0x0F;
            }
        }
    }
}

// Renkli print
void kprint_colored(const char* str, char color) {
    char old_color = 0x0F;
    while(*str) {
        if(*str == '\n') {
            cursor_x = 0;
            cursor_y++;
        } else {
            int index = (cursor_y * 80 + cursor_x) * 2;
            vga_buffer[index] = *str;
            vga_buffer[index + 1] = color;
            cursor_x++;
        }
        str++;
        
        if(cursor_x >= 80) {
            cursor_x = 0;
            cursor_y++;
        }
        
        if(cursor_y >= 25) {
            cursor_y = 24;
            for(int i = 0; i < 24 * 80; i++) {
                vga_buffer[i * 2] = vga_buffer[(i + 80) * 2];
                vga_buffer[i * 2 + 1] = vga_buffer[(i + 80) * 2 + 1];
            }
            for(int i = 24 * 80; i < 25 * 80; i++) {
                vga_buffer[i * 2] = ' ';
                vga_buffer[i * 2 + 1] = 0x0F;
            }
        }
    }
}

// Kernel yükle
void load_kernel() {
    kprint_colored("\nLAMAX64 Shell - Loading Kernel...\n", 0x0E);
    kprint("Loading /kernel/lamax64-1.0.0\n");
    
    // Yükleme animasyonu
    for(int i = 0; i < 20; i++) {
        kprint(".");
        // Basit gecikme
        for(volatile int j = 0; j < 1000000; j++) {}
    }
    
    kprint("\n");
    kprint_colored("Kernel loaded successfully!\n", 0x0A);
    kprint("Transferring control to kernel...\n\n");
    
    // Kernel'e geç
    void (*kernel_entry)() = (void(*)())0x100000;
    kernel_entry();
}

// Shell komutları
void execute_command(const char* cmd) {
    if(strcmp(cmd, "load") == 0) {
        load_kernel();
    }
    else if(strcmp(cmd, "help") == 0) {
        kprint_colored("LAMAX64 Shell Commands:\n", 0x0B);
        kprint("  load  - Load the kernel (/kernel/lamax64-1.0.0)\n");
        kprint("  help  - Show this help message\n");
        kprint("  about - Show system information\n");
    }
    else if(strcmp(cmd, "about") == 0) {
        kprint_colored("LAMAX64 Operating System v1.0.0\n", 0x0E);
        kprint("A 64-bit Unix-like operating system\n");
        kprint("Boot: MBR -> Disk Loader -> Shell -> Kernel\n");
        kprint("Built with hybrid Windows/Linux commands\n");
    }
    else if(strlen(cmd) > 0) {
        kprint_colored("Unknown command: ", 0x0C);
        kprint(cmd);
        kprint("\nType 'help' for available commands\n");
    }
}

// Basit klavye girişi simülasyonu
void get_input(char* buffer, int max_len) {
    // Gerçek implementasyonda keyboard interrupt handler kullanılır
    // Şimdilik otomatik olarak "load" komutunu çalıştır
    strcpy(buffer, "load");
}

// Ana shell döngüsü
void shell_main() {
    char input[128];
    
    // Shell başlangıç mesajı
    kprint_colored("========================================\n", 0x0B);
    kprint_colored("    LAMAX64 Operating System v1.0.0    \n", 0x0F);
    kprint_colored("========================================\n", 0x0B);
    kprint("\nShell initialized successfully!\n");
    kprint_colored("Type 'help' for available commands\n", 0x07);
    kprint_colored("Type 'load' to start the kernel\n\n", 0x0E);
    
    // Otomatik olarak kernel yükleme işlemini başlat
    kprint_colored("lamax-shell> ", 0x0A);
    kprint("load\n");
    
    // 2 saniye bekle
    for(volatile int i = 0; i < 5000000; i++) {}
    
    execute_command("load");
    
    // Shell döngüsü (gerçek implementasyonda sonsuz döngü olur)
    while(1) {
        kprint_colored("lamax-shell> ", 0x0A);
        get_input(input, 127);
        kprint(input);
        kprint("\n");
        execute_command(input);
    }
}
