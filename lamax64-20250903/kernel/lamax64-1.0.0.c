*
 * LAMAX64 Operating System Kernel
 * Version 1.0.0
 * A Unix-like 64-bit operating system with hybrid Windows/Linux commands
 */

#include "system.h"

// VGA ekran tamponu
volatile char* vga_buffer = (volatile char*)0xB8000;
int cursor_x = 0, cursor_y = 0;
char current_path[256] = "/";

// String fonksiyonları
int strcmp(const char* str1, const char* str2) {
    while(*str1 && (*str1 == *str2)) {
        str1++; str2++;
    }
    return *str1 - *str2;
}

int strlen(const char* str) {
    int len = 0;
    while(str[len]) len++;
    return len;
}

void strcpy(char* dest, const char* src) {
    while(*src) *dest++ = *src++;
    *dest = 0;
}

int strncmp(const char* str1, const char* str2, int n) {
    while(n-- && *str1 && (*str1 == *str2)) {
        str1++; str2++;
    }
    return n < 0 ? 0 : *str1 - *str2;
}

// Basit ekran çıktısı
void kprint(const char* str) {
    while(*str) {
        if(*str == '\n') {
            cursor_x = 0; cursor_y++;
        } else {
            int index = (cursor_y * 80 + cursor_x) * 2;
            vga_buffer[index] = *str;
            vga_buffer[index + 1] = 0x07;
            cursor_x++;
        }
        str++;
        if(cursor_x >= 80) { cursor_x = 0; cursor_y++; }
        if(cursor_y >= 25) {
            cursor_y = 24;
            for(int i = 0; i < 24 * 80; i++) {
                vga_buffer[i * 2] = vga_buffer[(i + 80) * 2];
                vga_buffer[i * 2 + 1] = vga_buffer[(i + 80) * 2 + 1];
            }
            for(int i = 24 * 80; i < 25 * 80; i++) {
                vga_buffer[i * 2] = ' ';
                vga_buffer[i * 2 + 1] = 0x07;
            }
        }
    }
}

void kprint_colored(const char* str, char color) {
    char old_attr = 0x07;
    while(*str) {
        if(*str == '\n') {
            cursor_x = 0; cursor_y++;
        } else {
            int index = (cursor_y * 80 + cursor_x) * 2;
            vga_buffer[index] = *str;
            vga_buffer[index + 1] = color;
            cursor_x++;
        }
        str++;
        if(cursor_x >= 80) { cursor_x = 0; cursor_y++; }
        if(cursor_y >= 25) {
            cursor_y = 24;
            for(int i = 0; i < 24 * 80; i++) {
                vga_buffer[i * 2] = vga_buffer[(i + 80) * 2];
                vga_buffer[i * 2 + 1] = vga_buffer[(i + 80) * 2 + 1];
            }
            for(int i = 24 * 80; i < 25 * 80; i++) {
                vga_buffer[i * 2] = ' ';
                vga_buffer[i * 2 + 1] = 0x07;
            }
        }
    }
}

// Kernel komutları (Windows/Linux karışımı)
void cmd_help() {
    kprint_colored("LAMAX64 Kernel v1.0.0 - Available Commands:\n\n", 0x0E);
    kprint_colored("File Operations:\n", 0x0B);
    kprint("  ls / dir     - List directory contents\n");
    kprint("  cd           - Change directory\n");
    kprint("  pwd          - Print working directory\n");
    kprint("  mkdir        - Create directory\n");
    kprint("  rmdir        - Remove directory\n");
    kprint("  cp / copy    - Copy files\n");
    kprint("  mv / move    - Move/rename files\n");
    kprint("  rm / del     - Delete files\n");
    kprint("  cat / type   - Display file contents\n\n");
    
    kprint_colored("System Commands:\n", 0x0B);
    kprint("  ps           - List running processes\n");
    kprint("  top          - Show system performance\n");
    kprint("  clear / cls  - Clear screen\n");
    kprint("  date         - Show system date/time\n");
    kprint("  uname        - System information\n");
    kprint("  ver          - System version\n");
    kprint("  exit         - Exit system\n");
    kprint("  shutdown     - Shutdown system\n");
    kprint("  reboot       - Restart system\n\n");
    
    kprint_colored("Network Commands:\n", 0x0B);
    kprint("  ping         - Network connectivity test\n");
    kprint("  netstat      - Network connections\n");
    kprint("  ipconfig     - Network configuration\n\n");
}

void cmd_clear() {
    for(int i = 0; i < 80 * 25; i++) {
        vga_buffer[i * 2] = ' ';
        vga_buffer[i * 2 + 1] = 0x07;
    }
    cursor_x = 0; cursor_y = 0;
}

void cmd_ls() {
    kprint_colored("Directory listing for ", 0x07);
    kprint_colored(current_path, 0x0E);
    kprint(":\n\n");
    kprint_colored("drwxr-xr-x  2 root root  4096 Sep 02 2025 ", 0x0B);
    kprint("bin/\n");
    kprint_colored("drwxr-xr-x  2 root root  4096 Sep 02 2025 ", 0x0B);
    kprint("etc/\n");
    kprint_colored("drwxr-xr-x  2 root root  4096 Sep 02 2025 ", 0x0B);
    kprint("home/\n");
    kprint_colored("drwxr-xr-x  2 root root  4096 Sep 02 2025 ", 0x0B);
    kprint("kernel/\n");
    kprint_colored("drwxr-xr-x  2 root root  4096 Sep 02 2025 ", 0x0B);
    kprint("usr/\n");
    kprint_colored("drwxr-xr-x  2 root root  4096 Sep 02 2025 ", 0x0B);
    kprint("var/\n");
    kprint_colored("-rw-r--r--  1 root root  1024 Sep 02 2025 ", 0x07);
    kprint("readme.txt\n");
    kprint_colored("-rwxr-xr-x  1 root root  8192 Sep 02 2025 ", 0x0A);
    kprint("lamax64-1.0.0\n");
}

void cmd_pwd() {
    kprint(current_path);
    kprint("\n");
}

void cmd_uname() {
    kprint_colored("LAMAX64 1.0.0 x86_64 GNU/Linux-compatible\n", 0x0E);
    kprint("Kernel: lamax64-1.0.0 #1 SMP\n");
    kprint("Architecture: x86_64\n");
    kprint("CPU: Intel/AMD 64-bit\n");
}

void cmd_ver() {
    kprint_colored("LAMAX64 Operating System\n", 0x0E);
    kprint("Version 1.0.0 (Build 20250902)\n");
    kprint("Copyright (c) 2025 LAMAX64 Project\n");
}

void cmd_ps() {
    kprint_colored("PID  PPID CMD\n", 0x0E);
    kprint("  1     0 init\n");
    kprint("  2     1 kernel\n");
    kprint("  3     2 shell\n");
    kprint("  4     1 idle\n");
}

void cmd_top() {
    kprint_colored("LAMAX64 System Monitor:\n\n", 0x0E);
    kprint("CPU Usage:    31 purna\n");
    kprint("Memory:       bu os o kadar gelismis degil\n");
    kprint("Uptime:       reis bu komutu 2.0.0 da gir\n");
    kprint("Processes:    2.0.0 da gelecek valla\n");
    kprint("Load average: 2.0.0 da gelecek\n");
}

void cmd_date() {
    kprint_colored("Tue Sep  2 14:30:45 UTC 2025\n", 0x0E);
}

void cmd_ipconfig() {
    kprint_colored("Network Configuration:\n\n", 0x0E);
    kprint("eth0: Link encap:Ethernet\n");
    kprint("      inet addr:192.168.1.100  Bcast:192.168.1.255  Mask:255.255.255.0\n");
    kprint("      UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1\n");
    kprint("      RX packets:0 errors:0 dropped:0 overruns:0 frame:0\n");
    kprint("      TX packets:0 errors:0 dropped:0 overruns:0 carrier:0\n");
}

void cmd_shutdown() {
    kprint_colored("System is shutting down...\n", 0x0C);
    kprint("Stopping services...\n");
    kprint("Unmounting filesystems...\n");
    kprint("System halted.\n");
    while(1) {} // Sistem durdur
}

void cmd_reboot() {
    kprint_colored("System is rebooting...\n", 0x0C);
    kprint("Stopping services...\n");
    kprint("Restarting...\n");
    // Gerçek implementasyonda CPU reset yapılır
    while(1) {}
}

// Komut çözümleyici
void execute_command(const char* cmd) {
    if(strcmp(cmd, "help") == 0) {
        cmd_help();
    }
    else if(strcmp(cmd, "clear") == 0 || strcmp(cmd, "cls") == 0) {
        cmd_clear();
    }
    else if(strcmp(cmd, "ls") == 0 || strcmp(cmd, "dir") == 0) {
        cmd_ls();
    }
    else if(strcmp(cmd, "pwd") == 0) {
        cmd_pwd();
    }
    else if(strcmp(cmd, "uname") == 0) {
        cmd_uname();
    }
    else if(strcmp(cmd, "ver") == 0) {
        cmd_ver();
    }
    else if(strcmp(cmd, "ps") == 0) {
        cmd_ps();
    }
    else if(strcmp(cmd, "top") == 0) {
        cmd_top();
    }
    else if(strcmp(cmd, "date") == 0) {
        cmd_date();
    }
    else if(strcmp(cmd, "ipconfig") == 0) {
        cmd_ipconfig();
    }
    else if(strcmp(cmd, "shutdown") == 0) {
        cmd_shutdown();
    }
    else if(strcmp(cmd, "reboot") == 0) {
        cmd_reboot();
    }
    else if(strcmp(cmd, "exit") == 0) {
        kprint_colored("Exiting to shell...\n", 0x0E);
        // Gerçek implementasyonda shell'e geri dön
    }
    else if(strncmp(cmd, "cd ", 3) == 0) {
        const char* path = cmd + 3;
        kprint_colored("Changing directory to: ", 0x07);
        kprint(path);
        kprint("\n");
        if(strlen(path) > 0 && strlen(path) < 200) {
            strcpy(current_path, path);
            if(current_path[strlen(current_path)-1] != '/') {
                int len = strlen(current_path);
                current_path[len] = '/';
                current_path[len+1] = 0;
            }
        }
    }
    else if(strncmp(cmd, "mkdir ", 6) == 0) {
        const char* dirname = cmd + 6;
        kprint_colored("Creating directory: ", 0x0A);
        kprint(dirname);
        kprint("\n");
    }
    else if(strncmp(cmd, "cat ", 4) == 0 || strncmp(cmd, "type ", 5) == 0) {
        const char* filename = (cmd[0] == 'c') ? cmd + 4 : cmd + 5;
        kprint_colored("Displaying file: ", 0x07);
        kprint(filename);
        kprint("\n");
        kprint_colored("This is a sample file content.\n", 0x0F);
        kprint("LAMAX64 OS file system simulation.\n");
    }
    else if(strncmp(cmd, "ping ", 5) == 0) {
        const char* host = cmd + 5;
        kprint_colored("PING ", 0x0E);
        kprint(host);
        kprint(" (192.168.1.1): 56 data bytes\n");
        kprint("64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=1.234 ms\n");
        kprint("64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=1.156 ms\n");
        kprint("64 bytes from 192.168.1.1: icmp_seq=3 ttl=64 time=1.089 ms\n");
    }
    else if(strcmp(cmd, "netstat") == 0) {
        kprint_colored("Active Internet connections:\n", 0x0E);
        kprint("Proto Recv-Q Send-Q Local Address          Foreign Address        State\n");
        kprint("tcp        0      0 0.0.0.0:22             0.0.0.0:*              LISTEN\n");
        kprint("tcp        0      0 127.0.0.1:25           0.0.0.0:*              LISTEN\n");
    }
    else if(strlen(cmd) > 0) {
        kprint_colored("Command not found: ", 0x0C);
        kprint(cmd);
        kprint("\nType 'help' for available commands.\n");
    }
}

// Basit input simülasyonu (gerçek implementasyonda keyboard handler kullanılır)
void get_kernel_input(char* buffer, int max_len) {
    // Demo amaçlı önceden tanımlı komutlar
    static int demo_step = 0;
    const char* demo_commands[] = {
        "help",
        "uname",
        "ls",
        "pwd",
        "ps",
        "top",
        "date",
        "clear",
        "ver",
        ""
    };
    
    if(demo_step < 9) {
        strcpy(buffer, demo_commands[demo_step]);
        demo_step++;
    } else {
        strcpy(buffer, "help");
        demo_step = 0;
    }
}

// Ana kernel entry point
void kernel_main() {
    char input[128];
    
    // Ekranı temizle
    cmd_clear();
    
    // Kernel başlangıç mesajı
    kprint_colored("================================================================\n", 0x0F);
    kprint_colored("                 LAMAX64 Operating System v1.0.0               \n", 0x0E);
    kprint_colored("              A Unix-like 64-bit Operating System              \n", 0x07);
    kprint_colored("================================================================\n", 0x0F);
    
    kprint("\n");
    kprint_colored("Kernel loaded successfully at 0x100000\n", 0x0A);
    kprint("Initializing system components...\n");
    
    // Sistem başlatma simülasyonu
    kprint("- Memory management: ");
    for(volatile int i = 0; i < 1000000; i++) {} // Gecikme
    kprint_colored("OK\n", 0x0A);
    
    kprint("- Process scheduler: ");
    for(volatile int i = 0; i < 1000000; i++) {}
    kprint_colored("OK\n", 0x0A);
    
    kprint("- File system: ");
    for(volatile int i = 0; i < 1000000; i++) {}
    kprint_colored("OK\n", 0x0A);
    
    kprint("- Network stack: ");
    for(volatile int i = 0; i < 1000000; i++) {}
    kprint_colored("OK\n", 0x0A);
    
    kprint("- Device drivers: ");
    for(volatile int i = 0; i < 1000000; i++) {}
    kprint_colored("OK\n", 0x0A);
    
    kprint("\n");
    kprint_colored("System initialization complete!\n", 0x0B);
    kprint_colored("Welcome to LAMAX64 - Type 'help' for available commands\n\n", 0x0F);
    
    // Ana kernel döngüsü
    int demo_count = 0;
    while(demo_count < 10) { // Demo için sınırlı döngü
        kprint_colored("root@lamax64:", 0x0A);
        kprint_colored(current_path, 0x0B);
        kprint_colored("# ", 0x0A);
        
        get_kernel_input(input, 127);
        kprint(input);
        kprint("\n");
        
        execute_command(input);
        kprint("\n");
        
        demo_count++;
        
        // Gecikme
        for(volatile int i = 0; i < 3000000; i++) {}
    }
    
    // Demo bitişi
    kprint_colored("\n=== LAMAX64 OS Demo Complete ===\n", 0x0E);
    kprint("This was a demonstration of the LAMAX64 operating system.\n");
    kprint("In a real implementation, the system would continue running.\n");
    kprint_colored("System halted.\n", 0x0C);
    
    while(1) {} // Sistem durdur
}
