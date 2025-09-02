# Assembly Bootloader Makefile
# Author: Assembly Bootloader Project
# Date: August 29, 2025

# Tools
NASM = nasm
QEMU = qemu-system-x86_64
DD = dd
HEXDUMP = hexdump

# Directories
SRC_DIR = .
BUILD_DIR = build
ISO_DIR = iso

# Files
BOOTLOADER = boot.asm
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin
BOOTLOADER_IMG = $(BUILD_DIR)/bootloader.img
DISK_BIN = $(BUILD_DIR)/disk.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
ISO_FILE = $(BUILD_DIR)/bootloader.iso

# NASM flags
NASM_FLAGS = -f bin -I $(SRC_DIR)/

# Default target
all: $(BOOTLOADER_IMG) $(DISK_BIN) $(KERNEL_BIN)
        @echo "Build complete. Bootloader image: $(BOOTLOADER_IMG)"

# Create build directory
$(BUILD_DIR):
        @mkdir -p $(BUILD_DIR)
        @echo "Created build directory: $(BUILD_DIR)"

# Compile bootloader
$(BOOTLOADER_BIN): $(BOOTLOADER) $(BUILD_DIR)
        @echo "Assembling bootloader..."
        $(NASM) $(NASM_FLAGS) -o $(BOOTLOADER_BIN) $(BOOTLOADER)
        @echo "Bootloader assembled: $(BOOTLOADER_BIN)"

# Create bootable disk image
$(BOOTLOADER_IMG): $(BOOTLOADER_BIN)
        @echo "Creating bootable disk image..."
        $(DD) if=/dev/zero of=$(BOOTLOADER_IMG) bs=512 count=2880
        $(DD) if=$(BOOTLOADER_BIN) of=$(BOOTLOADER_IMG) conv=notrunc
        @echo "Bootable disk image created: $(BOOTLOADER_IMG)"

# Create sample disk.bin
$(DISK_BIN): $(BUILD_DIR)
        @echo "Creating sample disk.bin..."
        $(DD) if=/dev/zero of=$(DISK_BIN) bs=1024 count=32
        @echo "DISK_BIN_SIGNATURE" > $(BUILD_DIR)/disk_header.txt
        $(DD) if=$(BUILD_DIR)/disk_header.txt of=$(DISK_BIN) conv=notrunc
        @echo "Sample disk.bin created: $(DISK_BIN)"

# Create enhanced kernel.bin with CLI
$(KERNEL_BIN): $(BUILD_DIR) kernel.asm
        @echo "Compiling enhanced CLI kernel..."
        $(NASM) $(NASM_FLAGS) -o $(KERNEL_BIN) kernel.asm
        @echo "Enhanced kernel.bin created: $(KERNEL_BIN)"

# Create ISO image for CD/DVD booting
iso: $(BOOTLOADER_IMG) $(DISK_BIN) $(KERNEL_BIN)
        @echo "Creating ISO image..."
        @mkdir -p $(ISO_DIR)
        @cp $(BOOTLOADER_IMG) $(ISO_DIR)/
        @cp $(DISK_BIN) $(ISO_DIR)/
        @cp $(KERNEL_BIN) $(ISO_DIR)/
        @if command -v genisoimage >/dev/null 2>&1; then \
                genisoimage -o $(ISO_FILE) -b bootloader.img -no-emul-boot -boot-load-size 4 -boot-info-table $(ISO_DIR); \
                echo "ISO image created: $(ISO_FILE)"; \
        else \
                echo "genisoimage not found. ISO creation skipped."; \
        fi

# Test with QEMU
test: $(BOOTLOADER_IMG)
        @echo "Testing bootloader with QEMU..."
        $(QEMU) -drive file=$(BOOTLOADER_IMG),format=raw,if=floppy -m 16M -display curses

# Test with QEMU GUI
test-gui: $(BOOTLOADER_IMG)
        @echo "Testing bootloader with QEMU GUI..."
        $(QEMU) -drive file=$(BOOTLOADER_IMG),format=raw,if=floppy -m 16M

# Test with hard disk emulation
test-hdd: $(BOOTLOADER_IMG) $(DISK_BIN) $(KERNEL_BIN)
        @echo "Testing with hard disk containing disk.bin and kernel.bin..."
        @# Create a larger disk image
        $(DD) if=/dev/zero of=$(BUILD_DIR)/harddisk.img bs=1M count=10
        @# Copy bootloader to first sector
        $(DD) if=$(BOOTLOADER_BIN) of=$(BUILD_DIR)/harddisk.img conv=notrunc
        @# Copy disk.bin to sector 2
        $(DD) if=$(DISK_BIN) of=$(BUILD_DIR)/harddisk.img bs=512 seek=1 conv=notrunc
        @# Copy kernel.bin inside disk.bin area
        $(DD) if=$(KERNEL_BIN) of=$(BUILD_DIR)/harddisk.img bs=512 seek=65 conv=notrunc
        $(QEMU) -drive file=$(BUILD_DIR)/harddisk.img,format=raw -m 16M

# Debug with hexdump
debug: $(BOOTLOADER_BIN)
        @echo "Bootloader hexdump:"
        $(HEXDUMP) -C $(BOOTLOADER_BIN) | head -20
        @echo ""
        @echo "Boot signature check:"
        @tail -c 2 $(BOOTLOADER_BIN) | $(HEXDUMP) -C

# Analyze binary
analyze: $(BOOTLOADER_BIN)
        @echo "Binary analysis:"
        @echo "Size: $$(wc -c < $(BOOTLOADER_BIN)) bytes"
        @echo "Should be exactly 512 bytes for boot sector"
        @if [ $$(wc -c < $(BOOTLOADER_BIN)) -eq 512 ]; then \
                echo "✓ Correct boot sector size"; \
        else \
                echo "✗ Incorrect size - should be 512 bytes"; \
        fi
        @echo ""
        @echo "Boot signature:"
        @if tail -c 2 $(BOOTLOADER_BIN) | xxd | grep -q "55aa"; then \
                echo "✓ Valid boot signature (0x55AA)"; \
        else \
                echo "✗ Invalid boot signature"; \
        fi

# Create virtual machine test environment
vm-test: $(BOOTLOADER_IMG) $(DISK_BIN) $(KERNEL_BIN)
        @echo "Setting up VM test environment..."
        @mkdir -p $(BUILD_DIR)/vm
        @cp $(BOOTLOADER_IMG) $(BUILD_DIR)/vm/
        @cp $(DISK_BIN) $(BUILD_DIR)/vm/
        @cp $(KERNEL_BIN) $(BUILD_DIR)/vm/
        @echo "VM test files ready in $(BUILD_DIR)/vm/"
        @echo "Use: qemu-system-x86_64 -drive file=$(BUILD_DIR)/vm/bootloader.img,format=raw,if=floppy"

# Clean build files
clean:
        @echo "Cleaning build files..."
        @rm -rf $(BUILD_DIR)
        @rm -rf $(ISO_DIR)
        @echo "Clean complete."

# Install development dependencies (Ubuntu/Debian)
install-deps:
        @echo "Installing development dependencies..."
        @if command -v apt-get >/dev/null 2>&1; then \
                sudo apt-get update; \
                sudo apt-get install -y nasm qemu-system-x86 genisoimage xxd; \
                echo "Dependencies installed successfully."; \
        else \
                echo "Please install: nasm qemu-system-x86 genisoimage xxd"; \
        fi

# Show build information
info:
        @echo "Assembly Bootloader Build System"
        @echo "================================"
        @echo "Source directory: $(SRC_DIR)"
        @echo "Build directory:  $(BUILD_DIR)"
        @echo "Main bootloader:  $(BOOTLOADER)"
        @echo "Output image:     $(BOOTLOADER_IMG)"
        @echo ""
        @echo "Available targets:"
        @echo "  all        - Build bootloader and sample files"
        @echo "  test       - Test with QEMU (text mode)"
        @echo "  test-gui   - Test with QEMU (GUI mode)"
        @echo "  test-hdd   - Test with hard disk emulation"
        @echo "  iso        - Create ISO image"
        @echo "  debug      - Show hexdump of bootloader"
        @echo "  analyze    - Analyze binary structure"
        @echo "  clean      - Remove build files"
        @echo "  install-deps - Install required tools"

# Phony targets
.PHONY: all test test-gui test-hdd debug analyze iso clean install-deps vm-test info

# Default goal
.DEFAULT_GOAL := all
