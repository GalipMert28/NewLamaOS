# LAMAX64 Operating System Makefile
# Version 1.0.0

# Derleyici ve araçlar
ASM = nasm
CC = gcc
LD = ld
OBJCOPY = objcopy
DD = dd

# Bayraklar
ASMFLAGS = -f bin
CFLAGS = -m32 -ffreestanding -fno-builtin -fno-stack-protector -nostdlib -nodefaultlibs \
         -Wall -Wextra -Werror -c
LDFLAGS = -m elf_i386 -T linker.ld

# Hedef dosyalar
BOOT_BIN = boot.bin
DISK_BIN = disk.bin
SHELL_BIN = shell.bin
KERNEL_BIN = lamax64-1.0.0.bin
OS_IMG = lamax64-os.img

# Kaynak dosyalar
BOOT_SRC = boot.asm
DISK_SRC = disk.c
SHELL_SRC = shell.c
KERNEL_SRC = lamax64-1.0.0.c

# Object dosyalar
BOOT_OBJ = boot.o
DISK_OBJ = disk.o
SHELL_OBJ = shell.o
KERNEL_OBJ = lamax64-1.0.0.o

# Ana hedef
all: $(OS_IMG)
	@echo "LAMAX64 OS Build Complete!"
	@echo "Image file: $(OS_IMG)"
	@echo "Size: `du -h $(OS_IMG) | cut -f1`"

# OS image oluştur
$(OS_IMG): $(BOOT_BIN) $(DISK_BIN) $(SHELL_BIN) $(KERNEL_BIN)
	@echo "Creating OS image..."
	$(DD) if=/dev/zero of=$(OS_IMG) bs=1024 count=1440
	$(DD) if=$(BOOT_BIN) of=$(OS_IMG) conv=notrunc
	$(DD) if=$(DISK_BIN) of=$(OS_IMG) seek=1 conv=notrunc
	$(DD) if=$(SHELL_BIN) of=$(OS_IMG) seek=5 conv=notrunc
	$(DD) if=$(KERNEL_BIN) of=$(OS_IMG) seek=13 conv=notrunc

# Boot loader
$(BOOT_BIN): $(BOOT_SRC) constants.inc
	@echo "Assembling boot loader..."
	$(ASM) $(ASMFLAGS) $(BOOT_SRC) -o $(BOOT_BIN)

# Disk loader
$(DISK_BIN): $(DISK_OBJ)
	@echo "Linking disk loader..."
	$(LD) $(LDFLAGS) $(DISK_OBJ) -o disk.elf
	$(OBJCOPY) -O binary -j .text disk.elf $(DISK_BIN)
	@# Sektör boyutuna hizala (512 byte)
	@SIZE=$$(stat -c%s $(DISK_BIN)); \
	SECTORS=$$((($${SIZE} + 511) / 512)); \
	$(DD) if=$(DISK_BIN) of=$(DISK_BIN).tmp bs=512 count=$$SECTORS conv=sync; \
	mv $(DISK_BIN).tmp $(DISK_BIN)

$(DISK_OBJ): $(DISK_SRC) system.h
	@echo "Compiling disk loader..."
	$(CC) $(CFLAGS) $(DISK_SRC) -o $(DISK_OBJ)

# Shell
$(SHELL_BIN): $(SHELL_OBJ)
	@echo "Linking shell..."
	$(LD) $(LDFLAGS) $(SHELL_OBJ) -o shell.elf
	$(OBJCOPY) -O binary -j .text shell.elf $(SHELL_BIN)
	@# Sektör boyutuna hizala
	@SIZE=$$(stat -c%s $(SHELL_BIN)); \
	SECTORS=$$((($${SIZE} + 511) / 512)); \
	$(DD) if=$(SHELL_BIN) of=$(SHELL_BIN).tmp bs=512 count=$$SECTORS conv=sync; \
	mv $(SHELL_BIN).tmp $(SHELL_BIN)

$(SHELL_OBJ): $(SHELL_SRC) system.h
	@echo "Compiling shell..."
	$(CC) $(CFLAGS) $(SHELL_SRC) -o $(SHELL_OBJ)

# Kernel
$(KERNEL_BIN): $(KERNEL_OBJ)
	@echo "Linking kernel..."
	$(LD) $(LDFLAGS) $(KERNEL_OBJ) -o kernel.elf
	$(OBJCOPY) -O binary -j .text kernel.elf $(KERNEL_BIN)
	@# Sektör boyutuna hizala
	@SIZE=$$(stat -c%s $(KERNEL_BIN)); \
	SECTORS=$$((($${SIZE} + 511) / 512)); \
	$(DD) if=$(KERNEL_BIN) of=$(KERNEL_BIN).tmp bs=512 count=$$SECTORS conv=sync; \
	mv $(KERNEL_BIN).tmp $(KERNEL_BIN)

$(KERNEL_OBJ): $(KERNEL_SRC) system.h
	@echo "Compiling kernel..."
	$(CC) $(CFLAGS) $(KERNEL_SRC) -o $(KERNEL_OBJ)

# QEMU ile test et
test: $(OS_IMG)
	@echo "Starting LAMAX64 OS in QEMU..."
	qemu-system-i386 -drive format=raw,file=$(OS_IMG),if=floppy -m 64M

# QEMU debug modu
debug: $(OS_IMG)
	@echo "Starting LAMAX64 OS in QEMU debug mode..."
	qemu-system-i386 -drive format=raw,file=$(OS_IMG),if=floppy -m 64M -s -S

# VirtualBox ile test et
vbox: $(OS_IMG)
	@echo "Creating VirtualBox disk..."
	VBoxManage convertfromraw $(OS_IMG) lamax64.vdi --format VDI
	@echo "VDI file created: lamax64.vdi"

# Dosya boyutlarını göster
info: $(OS_IMG)
	@echo "=== LAMAX64 OS Build Information ==="
	@echo "Boot loader: `stat -c%s $(BOOT_BIN)` bytes"
	@echo "Disk loader: `stat -c%s $(DISK_BIN)` bytes"
	@echo "Shell:       `stat -c%s $(SHELL_BIN)` bytes"
	@echo "Kernel:      `stat -c%s $(KERNEL_BIN)` bytes"
	@echo "Total image: `stat -c%s $(OS_IMG)` bytes"
	@echo "===================================="

# Disassembly
disasm: $(KERNEL_BIN)
	objdump -D -b binary -m i386 $(KERNEL_BIN) > kernel_disasm.txt
	objdump -D -b binary -m i386 $(SHELL_BIN) > shell_disasm.txt
	objdump -D -b binary -m i386 $(DISK_BIN) > disk_disasm.txt
	@echo "Disassembly files created."

# Temizle
clean:
	@echo "Cleaning build files..."
	rm -f *.bin *.o *.elf *.img *.vdi *_disasm.txt
	@echo "Clean complete."

# Yeniden derle
rebuild: clean all

# Yardım
help:
	@echo "LAMAX64 OS Build System"
	@echo "======================="
	@echo "Targets:"
	@echo "  all      - Build complete OS image"
	@echo "  test     - Run OS in QEMU"
	@echo "  debug    - Run OS in QEMU debug mode"
	@echo "  vbox     - Create VirtualBox VDI file"
	@echo "  info     - Show build information"
	@echo "  disasm   - Generate disassembly files"
	@echo "  clean    - Remove build files"
	@echo "  rebuild  - Clean and build"
	@echo "  help     - Show this help"

.PHONY: all test debug vbox info disasm clean rebuild help
