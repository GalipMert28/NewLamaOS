/*
 * LAMAX64 Operating System
 * System Header File
 * Version 1.0.0
 */

#ifndef SYSTEM_H
#define SYSTEM_H

// Temel tip tanımlamaları
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef signed char int8_t;
typedef signed short int16_t;
typedef signed int int32_t;
typedef signed long long int64_t;

// Boolean tip
typedef enum { false = 0, true = 1 } bool;

// NULL tanımı
#ifndef NULL
#define NULL ((void*)0)
#endif

// Bellek adresleri
#define VGA_BUFFER          0xB8000
#define KERNEL_START        0x100000
#define STACK_BASE          0x200000
#define HEAP_START          0x300000

// VGA renk kodları
#define VGA_COLOR_BLACK         0
#define VGA_COLOR_BLUE          1
#define VGA_COLOR_GREEN         2
#define VGA_COLOR_CYAN          3
#define VGA_COLOR_RED           4
#define VGA_COLOR_MAGENTA       5
#define VGA_COLOR_BROWN         6
#define VGA_COLOR_LIGHT_GREY    7
#define VGA_COLOR_DARK_GREY     8
#define VGA_COLOR_LIGHT_BLUE    9
#define VGA_COLOR_LIGHT_GREEN   10
#define VGA_COLOR_LIGHT_CYAN    11
#define VGA_COLOR_LIGHT_RED     12
#define VGA_COLOR_LIGHT_MAGENTA 13
#define VGA_COLOR_LIGHT_BROWN   14
#define VGA_COLOR_WHITE         15

// Sistem sabitleri
#define MAX_PROCESSES       64
#define MAX_FILES           256
#define MAX_PATH_LENGTH     256
#define MAX_FILENAME        64
#define PAGE_SIZE           4096
#define SECTOR_SIZE         512

// Hata kodları
#define ERROR_SUCCESS       0
#define ERROR_INVALID_PARAM 1
#define ERROR_NOT_FOUND     2
#define ERROR_NO_MEMORY     3
#define ERROR_IO_ERROR      4
#define ERROR_ACCESS_DENIED 5

// Process durumları
typedef enum {
    PROCESS_STATE_READY,
    PROCESS_STATE_RUNNING,
    PROCESS_STATE_BLOCKED,
    PROCESS_STATE_TERMINATED
} process_state_t;

// Process yapısı
typedef struct process {
    uint32_t pid;
    uint32_t ppid;
    char name[MAX_FILENAME];
    process_state_t state;
    uint32_t stack_pointer;
    uint32_t base_address;
    uint32_t memory_size;
    struct process* next;
} process_t;

// Dosya yapısı
typedef struct file {
    char name[MAX_FILENAME];
    uint32_t size;
    uint32_t attributes;
    uint32_t creation_time;
    uint32_t last_access;
    uint32_t data_offset;
    bool is_directory;
} file_t;

// Bellek bloku yapısı
typedef struct memory_block {
    uint32_t address;
    uint32_t size;
    bool is_free;
    struct memory_block* next;
} memory_block_t;

// Fonksiyon prototiplerileri

// Temel I/O fonksiyonları
void kprint(const char* str);
void kprint_colored(const char* str, uint8_t color);
void kprintf(const char* format, ...);

// String fonksiyonları
int strlen(const char* str);
int strcmp(const char* str1, const char* str2);
int strncmp(const char* str1, const char* str2, int n);
void strcpy(char* dest, const char* src);
void strncpy(char* dest, const char* src, int n);
char* strcat(char* dest, const char* src);

// Bellek fonksiyonları
void* kmalloc(uint32_t size);
void kfree(void* ptr);
void* memset(void* dest, int value, uint32_t count);
void* memcpy(void* dest, const void* src, uint32_t count);
int memcmp(const void* ptr1, const void* ptr2, uint32_t count);

// Process yönetimi
process_t* create_process(const char* name, uint32_t entry_point);
void terminate_process(uint32_t pid);
process_t* get_process(uint32_t pid);
void schedule_processes();

// Dosya sistemi
file_t* open_file(const char* filename);
void close_file(file_t* file);
int read_file(file_t* file, void* buffer, uint32_t size);
int write_file(file_t* file, const void* buffer, uint32_t size);
bool create_directory(const char* dirname);
bool delete_file(const char* filename);

// Interrupt fonksiyonları
void enable_interrupts();
void disable_interrupts();
void register_interrupt_handler(int interrupt, void (*handler)());

// Sistem çağrıları
int sys_exit(int status);
int sys_fork();
int sys_exec(const char* program);
int sys_wait(int* status);
int sys_kill(int pid, int signal);

// Port I/O
uint8_t inb(uint16_t port);
void outb(uint16_t port, uint8_t data);
uint16_t inw(uint16_t port);
void outw(uint16_t port, uint16_t data);
uint32_t inl(uint16_t port);
void outl(uint16_t port, uint32_t data);

// Makrolar
#define CLI() __asm__ volatile("cli")
#define STI() __asm__ volatile("sti")
#define HLT() __asm__ volatile("hlt")
#define NOP() __asm__ volatile("nop")

#define PANIC(msg) do { \
    disable_interrupts(); \
    kprint_colored("KERNEL PANIC: ", VGA_COLOR_LIGHT_RED); \
    kprint(msg); \
    kprint("\nSystem halted.\n"); \
    while(1) HLT(); \
} while(0)

#define ASSERT(condition) do { \
    if(!(condition)) { \
        kprintf("ASSERTION FAILED: %s at %s:%d\n", #condition, __FILE__, __LINE__); \
        PANIC("Assertion failed"); \
    } \
} while(0)

// Inline fonksiyonlar
static inline uint8_t make_color(uint8_t fg, uint8_t bg) {
    return fg | (bg << 4);
}

static inline uint16_t make_vga_entry(char c, uint8_t color) {
    return (uint16_t)c | ((uint16_t)color << 8);
}

// Global değişkenler (extern)
extern volatile char* vga_buffer;
extern int cursor_x, cursor_y;
extern process_t* current_process;
extern process_t* process_list;
extern bool interrupts_enabled;

#endif // SYSTEM_H
