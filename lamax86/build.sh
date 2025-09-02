#!/bin/bash
# Build script for Assembly Bootloader
# Author: Assembly Bootloader Project
# Date: August 29, 2025

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Assembly Bootloader"
BUILD_DIR="build"
SRC_DIR="."

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking build dependencies..."
    
    local missing_deps=()
    
    # Check for NASM
    if ! command -v nasm &> /dev/null; then
        missing_deps+=("nasm")
    fi
    
    # Check for QEMU
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        missing_deps+=("qemu-system-x86_64")
    fi
    
    # Check for basic utilities
    for cmd in dd hexdump xxd truncate; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "On Ubuntu/Debian, install with:"
        log_info "sudo apt-get install nasm qemu-system-x86 xxd coreutils"
        exit 1
    fi
    
    log_success "All dependencies found"
}

create_build_dir() {
    log_info "Creating build directory..."
    mkdir -p "$BUILD_DIR"
    log_success "Build directory created: $BUILD_DIR"
}

build_bootloader() {
    log_info "Building bootloader..."
    
    # Assemble the bootloader
    nasm -f bin -I "$SRC_DIR/" -o "$BUILD_DIR/bootloader.bin" boot.asm
    
    # Verify size
    local size=$(wc -c < "$BUILD_DIR/bootloader.bin")
    if [ "$size" -ne 512 ]; then
        log_error "Bootloader size is $size bytes, should be 512 bytes"
        exit 1
    fi
    
    # Verify boot signature
    local signature=$(tail -c 2 "$BUILD_DIR/bootloader.bin" | xxd -p)
    if [ "$signature" != "55aa" ]; then
        log_error "Invalid boot signature: $signature (should be 55aa)"
        exit 1
    fi
    
    log_success "Bootloader built successfully: $BUILD_DIR/bootloader.bin"
}

create_disk_image() {
    log_info "Creating bootable disk image..."
    
    # Create 1.44MB floppy disk image
    dd if=/dev/zero of="$BUILD_DIR/bootloader.img" bs=512 count=2880 status=none
    
    # Copy bootloader to first sector
    dd if="$BUILD_DIR/bootloader.bin" of="$BUILD_DIR/bootloader.img" conv=notrunc status=none
    
    log_success "Bootable disk image created: $BUILD_DIR/bootloader.img"
}

create_sample_files() {
    log_info "Creating sample disk.bin and kernel.bin..."
    
    # Create sample disk.bin
    dd if=/dev/zero of="$BUILD_DIR/disk.bin" bs=1024 count=32 status=none
    echo "DISK_BIN_SIGNATURE" > "$BUILD_DIR/disk_header.txt"
    dd if="$BUILD_DIR/disk_header.txt" of="$BUILD_DIR/disk.bin" conv=notrunc status=none
    rm "$BUILD_DIR/disk_header.txt"
    
    # Create enhanced CLI kernel.bin
    if [ -f "kernel.asm" ]; then
        log_info "Compiling enhanced CLI kernel..."
        nasm -f bin -o "$BUILD_DIR/kernel.bin" kernel.asm
        log_success "Enhanced CLI kernel compiled successfully"
    else
        log_warning "kernel.asm not found, creating simple kernel..."
        {
            printf '\x4C\x44\x52\x4B'  # KRDL signature
            printf '\x00\x20\x00\x00'  # Size: 8192 bytes  
            printf '\x00\x00\x02\x00'  # Entry point: 0x20000
            printf '\x90\x90\x90\x90'  # NOP instructions
        } > "$BUILD_DIR/kernel.bin"
        
        # Pad to 8192 bytes
        dd if=/dev/zero bs=1 count=8180 >> "$BUILD_DIR/kernel.bin" 2>/dev/null
        truncate -s 8192 "$BUILD_DIR/kernel.bin"
    fi
    
    log_success "Sample files created: disk.bin, kernel.bin"
}

create_test_harddisk() {
    log_info "Creating test hard disk image..."
    
    # Create 10MB hard disk image
    dd if=/dev/zero of="$BUILD_DIR/harddisk.img" bs=1M count=10 status=none
    
    # Install bootloader in MBR
    dd if="$BUILD_DIR/bootloader.bin" of="$BUILD_DIR/harddisk.img" conv=notrunc status=none
    
    # Place disk.bin starting at sector 2
    dd if="$BUILD_DIR/disk.bin" of="$BUILD_DIR/harddisk.img" bs=512 seek=1 conv=notrunc status=none
    
    # Place kernel.bin inside disk.bin area (at sector 65)  
    dd if="$BUILD_DIR/kernel.bin" of="$BUILD_DIR/harddisk.img" bs=512 seek=65 conv=notrunc status=none
    
    log_success "Test hard disk image created: $BUILD_DIR/harddisk.img"
}

analyze_build() {
    log_info "Analyzing build output..."
    
    echo "Build Analysis:"
    echo "==============="
    
    # Bootloader analysis
    if [ -f "$BUILD_DIR/bootloader.bin" ]; then
        local size=$(wc -c < "$BUILD_DIR/bootloader.bin")
        echo "Bootloader size: $size bytes"
        
        echo "First 32 bytes (hex):"
        head -c 32 "$BUILD_DIR/bootloader.bin" | xxd
        
        echo "Boot signature:"
        tail -c 2 "$BUILD_DIR/bootloader.bin" | xxd
        
        echo "Instructions at start:"
        objdump -D -b binary -m i386 -M intel "$BUILD_DIR/bootloader.bin" | head -10
    fi
    
    # File sizes
    echo "File sizes:"
    ls -la "$BUILD_DIR"/*.bin "$BUILD_DIR"/*.img 2>/dev/null || true
}

run_tests() {
    log_info "Running basic tests..."
    
    # Test 1: Bootloader size
    local size=$(wc -c < "$BUILD_DIR/bootloader.bin")
    if [ "$size" -eq 512 ]; then
        log_success "✓ Bootloader size test passed"
    else
        log_error "✗ Bootloader size test failed: $size bytes"
        return 1
    fi
    
    # Test 2: Boot signature
    local signature=$(tail -c 2 "$BUILD_DIR/bootloader.bin" | xxd -p)
    if [ "$signature" = "55aa" ]; then
        log_success "✓ Boot signature test passed"
    else
        log_error "✗ Boot signature test failed: $signature"
        return 1
    fi
    
    # Test 3: File existence
    for file in bootloader.bin bootloader.img disk.bin kernel.bin; do
        if [ -f "$BUILD_DIR/$file" ]; then
            log_success "✓ File exists: $file"
        else
            log_error "✗ Missing file: $file"
            return 1
        fi
    done
    
    log_success "All tests passed!"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --clean    Clean build directory first"
    echo "  -t, --test     Run QEMU test after build"
    echo "  -a, --analyze  Show detailed build analysis"
    echo "  -q, --quick    Quick build (skip tests and analysis)"
    echo ""
    echo "Examples:"
    echo "  $0                 # Standard build"
    echo "  $0 --clean --test  # Clean build and test"
    echo "  $0 --analyze       # Build with analysis"
}

main() {
    local clean_first=false
    local run_qemu_test=false
    local show_analysis=false
    local quick_build=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                clean_first=true
                shift
                ;;
            -t|--test)
                run_qemu_test=true
                shift
                ;;
            -a|--analyze)
                show_analysis=true
                shift
                ;;
            -q|--quick)
                quick_build=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "========================================="
    echo "$PROJECT_NAME - Build System"
    echo "========================================="
    
    # Clean if requested
    if [ "$clean_first" = true ]; then
        log_info "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
        log_success "Build directory cleaned"
    fi
    
    # Check dependencies
    check_dependencies
    
    # Build process
    create_build_dir
    build_bootloader
    create_disk_image
    create_sample_files
    create_test_harddisk
    
    # Run tests unless quick build
    if [ "$quick_build" = false ]; then
        run_tests
    fi
    
    # Show analysis if requested
    if [ "$show_analysis" = true ]; then
        analyze_build
    fi
    
    # Run QEMU test if requested
    if [ "$run_qemu_test" = true ]; then
        log_info "Starting QEMU test..."
        log_info "Press Ctrl+A then X to exit QEMU"
        qemu-system-x86_64 -drive file="$BUILD_DIR/bootloader.img",format=raw,if=floppy -m 16M -display curses
    fi
    
    echo "========================================="
    log_success "Build completed successfully!"
    echo "Files created:"
    echo "  - $BUILD_DIR/bootloader.bin  (Boot sector)"
    echo "  - $BUILD_DIR/bootloader.img  (Floppy image)"
    echo "  - $BUILD_DIR/harddisk.img    (Hard disk image)"
    echo "  - $BUILD_DIR/disk.bin        (Sample disk.bin)"
    echo "  - $BUILD_DIR/kernel.bin      (Sample kernel.bin)"
    echo ""
    echo "Test with: qemu-system-x86_64 -drive file=$BUILD_DIR/bootloader.img,format=raw,if=floppy"
    echo "========================================="
}

# Run main function with all arguments
main "$@"
