; Sabitler ve Tanımlar
; Tüm modüller tarafından kullanılan paylaşılan sabitler

; Bellek segmentleri ve adresleri
BOOT_SEGMENT        equ 0x07C0
DISK_BIN_SEGMENT    equ 0x1000      ; disk.bin yükleme segmenti
KERNEL_SEGMENT      equ 0x2000      ; kernel.bin yükleme segmenti
KERNEL_PARAM_SEGMENT equ 0x0500     ; Kernel parametreleri segmenti

; Bellek boyutları
DISK_BIN_SIZE       equ 0x8000      ; disk.bin için maksimum boyut (32KB)
MAX_KERNEL_SIZE     equ 0x10000     ; Maksimum kernel boyutu (64KB)
DEFAULT_KERNEL_SIZE equ 0x4000      ; Varsayılan kernel boyutu (16KB)

; GDT segment seçicileri
CODE_SEG            equ 0x08        ; Kod segmenti seçicisi
DATA_SEG            equ 0x10        ; Veri segmenti seçicisi

; Dosya imzaları
KERNEL_SIGNATURE    equ 0x4B52444C  ; 'KRDL' - Kernel imzası

; Hardware constants
PCI_CONFIG_ADDRESS  equ 0x0CF8
PCI_CONFIG_DATA     equ 0x0CFC

; VGA constants
VGA_MEMORY          equ 0xA000
VGA_TEXT_MEMORY     equ 0xB800
VGA_WIDTH           equ 320
VGA_HEIGHT          equ 200

; Disk constants
FLOPPY_DRIVE_A      equ 0x00
FLOPPY_DRIVE_B      equ 0x01
HARD_DRIVE_0        equ 0x80
HARD_DRIVE_1        equ 0x81

; BIOS interrupts
INT_DISK            equ 0x13
INT_VIDEO           equ 0x10
INT_KEYBOARD        equ 0x16
INT_MEMORY          equ 0x15
INT_PCI             equ 0x1A

; Error codes
ERROR_DISK_NOT_FOUND    equ 0x01
ERROR_KERNEL_NOT_FOUND  equ 0x02
ERROR_INVALID_SIGNATURE equ 0x03
ERROR_MEMORY_ERROR      equ 0x04
ERROR_PROTECTED_MODE    equ 0x05

; Boot flags
SECURE_BOOT_FLAG    equ 0x01
VGA_INIT_FLAG       equ 0x02
KERNEL_LOADED_FLAG  equ 0x04
PROTECTED_MODE_FLAG equ 0x08

; ASCII constants
ASCII_NULL          equ 0x00
ASCII_CR            equ 0x0D
ASCII_LF            equ 0x0A
ASCII_SPACE         equ 0x20

; Color constants (VGA)
COLOR_BLACK         equ 0x00
COLOR_BLUE          equ 0x01
COLOR_GREEN         equ 0x02
COLOR_CYAN          equ 0x03
COLOR_RED           equ 0x04
COLOR_MAGENTA       equ 0x05
COLOR_BROWN         equ 0x06
COLOR_LIGHT_GRAY    equ 0x07
COLOR_DARK_GRAY     equ 0x08
COLOR_LIGHT_BLUE    equ 0x09
COLOR_LIGHT_GREEN   equ 0x0A
COLOR_LIGHT_CYAN    equ 0x0B
COLOR_LIGHT_RED     equ 0x0C
COLOR_LIGHT_MAGENTA equ 0x0D
COLOR_YELLOW        equ 0x0E
COLOR_WHITE         equ 0x0F
