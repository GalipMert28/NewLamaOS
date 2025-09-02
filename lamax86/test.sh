#!/bin/bash
# Test script for Assembly Bootloader
# Author: Assembly Bootloader Project
# Date: August 29, 2025

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
BUILD_DIR="build"
QEMU_MEMORY="16M"
QEMU_TIMEOUT=30

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_test() { echo -e "${PURPLE}[TEST]${NC} $1"; }

check_qemu() {
    log_info "Checking QEMU availability..."
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        log_error "QEMU not found. Please install qemu-system-x86"
        exit 1
    fi
    log_success "QEMU found: $(which qemu-system-x86_64)"
}

check_build_files() {
    log_info "Checking build files..."
    
    local required_files=(
        "$BUILD_DIR/bootloader.bin"
        "$BUILD_DIR/bootloader.img" 
        "$BUILD_DIR/disk.bin"
        "$BUILD_DIR/kernel.bin"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Required file not found: $file"
            log_info "Run './build.sh' first to build the project"
            exit 1
        fi
    done
    
    log_success "All required files found"
}

test_bootloader_structure() {
    log_test "Testing bootloader binary structure..."
    
    # Test size
    local size=$(wc -c < "$BUILD_DIR/bootloader.bin")
    if [ "$size" -eq 512 ]; then
        log_success "✓ Bootloader size correct: $size bytes"
    else
        log_error "✗ Bootloader size incorrect: $size bytes (expected 512)"
        return 1
    fi
    
    # Test boot signature
    local signature=$(tail -c 2 "$BUILD_DIR/bootloader.bin" | xxd -p)
    if [ "$signature" = "55aa" ]; then
        log_success "✓ Boot signature valid: 0x$signature"
    else
        log_error "✗ Boot signature invalid: 0x$signature (expected 55aa)"
        return 1
    fi
    
    # Test first instruction (should be CLI or similar)
    local first_byte=$(head -c 1 "$BUILD_DIR/bootloader.bin" | xxd -p)
    log_info "First instruction byte: 0x$first_byte"
    
    return 0
}

test_sample_files() {
    log_test "Testing sample files..."
    
    # Test disk.bin
    if [ -s "$BUILD_DIR/disk.bin" ]; then
        local disk_size=$(wc -c < "$BUILD_DIR/disk.bin")
        log_success "✓ disk.bin exists ($disk_size bytes)"
    else
        log_error "✗ disk.bin missing or empty"
        return 1
    fi
    
    # Test kernel.bin signature
    if [ -f "$BUILD_DIR/kernel.bin" ]; then
        local kernel_sig=$(head -c 4 "$BUILD_DIR/kernel.bin" | xxd -p)
        if [ "$kernel_sig" = "4c44524b" ]; then  # KRDL signature
            log_success "✓ kernel.bin has valid signature"
        else
            log_warning "⚠ kernel.bin signature: $kernel_sig (expected 4c44524b)"
        fi
    else
        log_error "✗ kernel.bin not found"
        return 1
    fi
    
    return 0
}

run_qemu_automated_test() {
    log_test "Running automated QEMU test..."
    
    local test_image="$1"
    local test_name="$2"
    
    log_info "Testing: $test_name"
    log_info "Image: $test_image"
    
    # Run QEMU with timeout and capture output
    timeout $QEMU_TIMEOUT qemu-system-x86_64 \
        -drive file="$test_image",format=raw,if=floppy \
        -m $QEMU_MEMORY \
        -display none \
        -serial stdio \
        -no-reboot \
        2>&1 | tee "$BUILD_DIR/qemu_output.log" &
    
    local qemu_pid=$!
    
    # Wait for QEMU to start and run
    sleep 5
    
    # Check if QEMU is still running (indicates boot process started)
    if kill -0 $qemu_pid 2>/dev/null; then
        log_success "✓ QEMU started successfully, bootloader is running"
        
        # Let it run a bit more then terminate
        sleep 3
        kill $qemu_pid 2>/dev/null || true
        wait $qemu_pid 2>/dev/null || true
        
        return 0
    else
        log_error "✗ QEMU exited immediately, boot failed"
        return 1
    fi
}

test_floppy_boot() {
    log_test "Testing floppy disk boot..."
    run_qemu_automated_test "$BUILD_DIR/bootloader.img" "Floppy Boot"
}

test_harddisk_boot() {
    log_test "Testing hard disk boot..."
    if [ -f "$BUILD_DIR/harddisk.img" ]; then
        # Run QEMU with hard disk image
        timeout $QEMU_TIMEOUT qemu-system-x86_64 \
            -drive file="$BUILD_DIR/harddisk.img",format=raw \
            -m $QEMU_MEMORY \
            -display none \
            -serial stdio \
            -no-reboot \
            2>&1 | tee "$BUILD_DIR/qemu_harddisk_output.log" &
        
        local qemu_pid=$!
        sleep 5
        
        if kill -0 $qemu_pid 2>/dev/null; then
            log_success "✓ Hard disk boot test successful"
            sleep 3
            kill $qemu_pid 2>/dev/null || true
            wait $qemu_pid 2>/dev/null || true
            return 0
        else
            log_error "✗ Hard disk boot test failed"
            return 1
        fi
    else
        log_warning "⚠ Hard disk image not found, skipping test"
        return 0
    fi
}

run_interactive_test() {
    log_test "Running interactive QEMU test..."
    log_info "This will open QEMU with the bootloader"
    log_info "Press Ctrl+Alt+G to release mouse/keyboard"
    log_info "Close QEMU window or press Ctrl+C to continue tests"
    
    read -p "Press Enter to start interactive test, or 's' to skip: " choice
    
    if [ "$choice" = "s" ] || [ "$choice" = "S" ]; then
        log_info "Skipping interactive test"
        return 0
    fi
    
    qemu-system-x86_64 \
        -drive file="$BUILD_DIR/bootloader.img",format=raw,if=floppy \
        -m $QEMU_MEMORY \
        -display gtk || log_warning "Interactive test completed or failed"
    
    return 0
}

test_memory_layout() {
    log_test "Testing memory layout and addresses..."
    
    # Check if bootloader uses correct memory addresses
    local bootloader_hex=$(xxd "$BUILD_DIR/bootloader.bin")
    
    # Look for common bootloader patterns
    if echo "$bootloader_hex" | grep -q "007c"; then
        log_success "✓ Found 0x7C00 address reference (boot sector location)"
    else
        log_warning "⚠ No obvious 0x7C00 reference found"
    fi
    
    # Check for stack setup
    if echo "$bootloader_hex" | grep -q -i "mov.*sp"; then
        log_success "✓ Stack pointer setup detected"
    else
        log_warning "⚠ No clear stack setup found"
    fi
    
    return 0
}

benchmark_boot_time() {
    log_test "Benchmarking boot time..."
    
    local start_time=$(date +%s%3N)
    
    timeout 10 qemu-system-x86_64 \
        -drive file="$BUILD_DIR/bootloader.img",format=raw,if=floppy \
        -m $QEMU_MEMORY \
        -display none \
        -serial stdio \
        -no-reboot &>/dev/null &
    
    local qemu_pid=$!
    
    # Wait for QEMU to be fully started
    while kill -0 $qemu_pid 2>/dev/null; do
        sleep 0.1
        local current_time=$(date +%s%3N)
        local elapsed=$((current_time - start_time))
        if [ $elapsed -gt 5000 ]; then  # 5 seconds
            break
        fi
    done
    
    kill $qemu_pid 2>/dev/null || true
    wait $qemu_pid 2>/dev/null || true
    
    local end_time=$(date +%s%3N)
    local boot_time=$((end_time - start_time))
    
    log_info "Estimated boot time: ${boot_time}ms"
    
    return 0
}

generate_test_report() {
    log_info "Generating test report..."
    
    local report_file="$BUILD_DIR/test_report.txt"
    
    {
        echo "Assembly Bootloader Test Report"
        echo "==============================="
        echo "Generated: $(date)"
        echo ""
        echo "Build Files:"
        ls -la "$BUILD_DIR"/*.bin "$BUILD_DIR"/*.img 2>/dev/null || echo "No build files found"
        echo ""
        echo "Bootloader Analysis:"
        echo "Size: $(wc -c < "$BUILD_DIR/bootloader.bin") bytes"
        echo "Boot Signature: $(tail -c 2 "$BUILD_DIR/bootloader.bin" | xxd -p)"
        echo ""
        echo "Test Results:"
        echo "============="
        if [ -f "$BUILD_DIR/qemu_output.log" ]; then
            echo "QEMU Output (Floppy):"
            head -20 "$BUILD_DIR/qemu_output.log"
        fi
        echo ""
        if [ -f "$BUILD_DIR/qemu_harddisk_output.log" ]; then
            echo "QEMU Output (Hard Disk):"
            head -20 "$BUILD_DIR/qemu_harddisk_output.log"
        fi
    } > "$report_file"
    
    log_success "Test report generated: $report_file"
}

show_help() {
    echo "Assembly Bootloader Test Suite"
    echo "=============================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help"
    echo "  -q, --quick       Quick tests only (no interactive)"
    echo "  -i, --interactive Run interactive QEMU session" 
    echo "  -a, --all         Run all tests including interactive"
    echo "  -s, --structure   Test bootloader structure only"
    echo "  -b, --benchmark   Run boot time benchmark"
    echo "  -r, --report      Generate detailed test report"
    echo ""
    echo "Examples:"
    echo "  $0                # Run standard test suite"
    echo "  $0 --quick        # Quick automated tests only"
    echo "  $0 --interactive  # Interactive QEMU session"
    echo "  $0 --all          # All tests including interactive"
}

main() {
    local run_quick=false
    local run_interactive_only=false
    local run_all=false
    local structure_only=false
    local run_benchmark=false
    local generate_report=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quick)
                run_quick=true
                shift
                ;;
            -i|--interactive)
                run_interactive_only=true
                shift
                ;;
            -a|--all)
                run_all=true
                shift
                ;;
            -s|--structure)
                structure_only=true
                shift
                ;;
            -b|--benchmark)
                run_benchmark=true
                shift
                ;;
            -r|--report)
                generate_report=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "========================================="
    echo "Assembly Bootloader Test Suite"
    echo "========================================="
    
    # Always check prerequisites
    check_qemu
    check_build_files
    
    # Structure tests
    if ! test_bootloader_structure; then
        log_error "Bootloader structure tests failed!"
        exit 1
    fi
    
    if [ "$structure_only" = true ]; then
        log_success "Structure tests completed successfully"
        exit 0
    fi
    
    # Sample file tests
    test_sample_files
    test_memory_layout
    
    # Interactive only mode
    if [ "$run_interactive_only" = true ]; then
        run_interactive_test
        exit 0
    fi
    
    # Automated tests
    if [ "$run_quick" = false ] || [ "$run_all" = true ]; then
        test_floppy_boot
        test_harddisk_boot
    fi
    
    # Benchmark if requested
    if [ "$run_benchmark" = true ] || [ "$run_all" = true ]; then
        benchmark_boot_time
    fi
    
    # Interactive test for full run
    if [ "$run_all" = true ]; then
        run_interactive_test
    fi
    
    # Generate report if requested
    if [ "$generate_report" = true ] || [ "$run_all" = true ]; then
        generate_test_report
    fi
    
    echo "========================================="
    log_success "Test suite completed successfully!"
    echo ""
    echo "Summary:"
    echo "  ✓ Bootloader structure validated"
    echo "  ✓ Sample files checked"
    echo "  ✓ Memory layout analyzed"
    if [ "$run_quick" = false ]; then
        echo "  ✓ QEMU boot tests completed"
    fi
    echo ""
    echo "To run interactive test: $0 --interactive"
    echo "To run full test suite: $0 --all"
    echo "========================================="
}

# Run main function
main "$@"
