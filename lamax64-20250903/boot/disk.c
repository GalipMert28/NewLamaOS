/*
 * LAMAX64 OS - Disk Loader
 * Version 1.0.0
 */

#include "system.h"

// VGA ekran tamponu
volatile char* vga_buffer = (volatile char*)0xB8000;
int cursor_x = 0, cursor_y = 0;

// Basit printf benzeri fonksiyon
void kprint(const char* str) {
    while(*str) {
        if(*str == '\n') {
            cursor_x = 0;
            cursor_y++;
        } else {
            int index = (cursor_y * 80 + cursor_x) * 2;
            vga_buffer[index] = *str;
            vga_buffer[index + 1] = 0x07; // Beyaz yazı, siyah arkaplan
            cursor_x++;
        }
        str++;
        
        if(cursor_x >= 80) {
            cursor_x = 0;
            cursor_y++;
        }
        
        if(cursor_y >= 25) {
            cursor_y = 24;
            // Ekranı kaydır (basit implementasyon)
            for(int i = 0; i < 24 * 80; i++) {
                vga_buffer[i * 2] = vga_buffer[(i + 80) * 2];
                vga_buffer[i * 2 + 1] = vga_buffer[(i + 80) * 2 + 1];
            }
            // Son satırı temizle
            for(int i = 24 * 80; i < 25 * 80; i++) {
                vga_buffer[i * 2] = ' ';
                vga_buffer[i * 2 + 1] = 0x07;
            }
        }
    }
}

// Basit disk okuma fonksiyonu (gerçek implementasyon BIOS int 13h kullanır)
int read_disk_sectors(int sector, int count, void* buffer) {
    // Bu gerçek bir implementasyonda assembly ile BIOS çağrısı yapılır
    // Şimdilik simülasyon amaçlı
    kprint("Reading sectors from disk...\n");
    return 0; // Başarı
}

// Shell.bin'i yükle ve çalıştır
void load_shell() {
    kprint("LAMAX64 Disk Loader v1.0.0\n");
    kprint("Loading shell.bin...\n");
    
    // Shell.bin'i belirli sektörlerden oku
    char* shell_buffer = (char*)0x9000;
    
    if(read_disk_sectors(6, 8, shell_buffer) != 0) {
        kprint("ERROR: Failed to load shell.bin!\n");
        while(1) {} // Sistem durdur
    }
    
    kprint("Shell loaded successfully!\n");
    kprint("Transferring control to shell...\n\n");
    
    // Shell'e geç (function pointer olarak çağır)
    void (*shell_entry)() = (void(*)())0x9000;
    shell_entry();
}

// Ana entry point
void disk_main() {
    // Ekranı temizle
    for(int i = 0; i < 80 * 25; i++) {
        vga_buffer[i * 2] = ' ';
        vga_buffer[i * 2 + 1] = 0x07;
    }
    
    cursor_x = 0;
    cursor_y = 0;
    
    load_shell();
    
    // Buraya ulaşmamalı
    while(1) {}
}
