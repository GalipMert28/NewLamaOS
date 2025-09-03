#ifndef ACPI_H
#define ACPI_H

#include <system.h>
#include <stdint.h>
#include <stdbool.h>

// ACPI Table Header
typedef struct {
    char signature[4];
    uint32_t length;
    uint8_t revision;
    uint8_t checksum;
    char oem_id[6];
    char oem_table_id[8];
    uint32_t oem_revision;
    uint32_t creator_id;
    uint32_t creator_revision;
} acpi_table_header_t;

// RSDP (Root System Description Pointer)
typedef struct {
    char signature[8];
    uint8_t checksum;
    char oem_id[6];
    uint8_t revision;
    uint32_t rsdt_address;
    // ACPI 2.0+ fields
    uint32_t length;
    uint64_t xsdt_address;
    uint8_t extended_checksum;
    uint8_t reserved[3];
} __attribute__((packed)) acpi_rsdp_t;

// RSDT (Root System Description Table)
typedef struct {
    acpi_table_header_t header;
    uint32_t entries[];
} __attribute__((packed)) acpi_rsdt_t;

// XSDT (Extended System Description Table)
typedef struct {
    acpi_table_header_t header;
    uint64_t entries[];
} __attribute__((packed)) acpi_xsdt_t;

// MADT (Multiple APIC Description Table)
typedef struct {
    acpi_table_header_t header;
    uint32_t local_apic_address;
    uint32_t flags;
    uint8_t entries[];
} __attribute__((packed)) acpi_madt_t;

// MADT Entry Types
#define ACPI_MADT_LOCAL_APIC       0
#define ACPI_MADT_IO_APIC          1
#define ACPI_MADT_INTERRUPT_OVERRIDE 2
#define ACPI_MADT_NMI_SOURCE       3
#define ACPI_MADT_LOCAL_APIC_NMI   4
#define ACPI_MADT_LOCAL_APIC_ADDR_OVERRIDE 5
#define ACPI_MADT_IO_SAPIC         6
#define ACPI_MADT_LOCAL_SAPIC      7
#define ACPI_MADT_PLATFORM_INT_SRC 8
#define ACPI_MADT_LOCAL_X2APIC     9
#define ACPI_MADT_LOCAL_X2APIC_NMI 10

// MADT Entry Header
typedef struct {
    uint8_t type;
    uint8_t length;
} __attribute__((packed)) acpi_madt_entry_header_t;

// Local APIC Entry
typedef struct {
    acpi_madt_entry_header_t header;
    uint8_t processor_id;
    uint8_t apic_id;
    uint32_t flags;
} __attribute__((packed)) acpi_madt_local_apic_t;

// IO APIC Entry
typedef struct {
    acpi_madt_entry_header_t header;
    uint8_t io_apic_id;
    uint8_t reserved;
    uint32_t io_apic_address;
    uint32_t global_system_interrupt_base;
} __attribute__((packed)) acpi_madt_io_apic_t;

// Interrupt Source Override Entry
typedef struct {
    acpi_madt_entry_header_t header;
    uint8_t bus;
    uint8_t source;
    uint32_t global_system_interrupt;
    uint16_t flags;
} __attribute__((packed)) acpi_madt_interrupt_override_t;

// MCFG (Memory Mapped Configuration Space)
typedef struct {
    acpi_table_header_t header;
    uint64_t reserved;
    struct {
        uint64_t base_address;
        uint16_t pci_segment_group;
        uint8_t start_bus;
        uint8_t end_bus;
        uint32_t reserved;
    } __attribute__((packed)) entries[];
} __attribute__((packed)) acpi_mcfg_t;

// FADT (Fixed ACPI Description Table)
typedef struct {
    acpi_table_header_t header;
    uint32_t firmware_ctrl;
    uint32_t dsdt;
    uint8_t reserved;
    uint8_t preferred_pm_profile;
    uint16_t sci_interrupt;
    uint32_t smi_cmd_port;
    uint8_t acpi_enable;
    uint8_t acpi_disable;
    uint8_t s4bios_req;
    uint8_t pstate_control;
    uint32_t pm1a_event_block;
    uint32_t pm1b_event_block;
    uint32_t pm1a_control_block;
    uint32_t pm1b_control_block;
    uint32_t pm2_control_block;
    uint32_t pm_timer_block;
    uint32_t gpe0_block;
    uint32_t gpe1_block;
    uint8_t pm1_event_length;
    uint8_t pm1_control_length;
    uint8_t pm2_control_length;
    uint8_t pm_timer_length;
    uint8_t gpe0_length;
    uint8_t gpe1_length;
    uint8_t gpe1_base;
    uint8_t cstate_control;
    uint16_t worst_c2_latency;
    uint16_t worst_c3_latency;
    uint16_t flush_size;
    uint16_t flush_stride;
    uint8_t duty_offset;
    uint8_t duty_width;
    uint8_t day_alarm;
    uint8_t month_alarm;
    uint8_t century;
    uint16_t boot_architecture_flags;
    uint8_t reserved2;
    uint32_t flags;
    // ACPI 2.0+ fields
    uint32_t reset_reg[3];
    uint8_t reset_value;
    uint8_t reserved3[3];
    uint64_t x_firmware_control;
    uint64_t x_dsdt;
    uint32_t x_pm1a_event_block[3];
    uint32_t x_pm1b_event_block[3];
    uint32_t x_pm1a_control_block[3];
    uint32_t x_pm1b_control_block[3];
    uint32_t x_pm2_control_block[3];
    uint32_t x_pm_timer_block[3];
    uint32_t x_gpe0_block[3];
    uint32_t x_gpe1_block[3];
} __attribute__((packed)) acpi_fadt_t;

// DSDT (Differentiated System Description Table)
typedef struct {
    acpi_table_header_t header;
    uint8_t definition_block[];
} __attribute__((packed)) acpi_dsdt_t;

// Function Prototypes
bool acpi_init(void);
void *acpi_find_table(const char *signature, uint32_t index);
acpi_rsdp_t *acpi_find_rsdp(void);
acpi_mcfg_t *acpi_get_mcfg(void);
acpi_madt_t *acpi_get_madt(void);
uint32_t acpi_get_io_apic_count(void);
uint32_t acpi_get_io_apic_address(uint32_t index);
uint32_t acpi_get_io_apic_gsib(uint32_t index);
uint32_t acpi_get_interrupt_override_count(void);
bool acpi_get_interrupt_override(uint32_t index, uint8_t *bus, uint8_t *source, 
                                uint32_t *global_interrupt, uint16_t *flags);
void acpi_enable(void);
void acpi_disable(void);
void acpi_reboot(void);
void acpi_shutdown(void);
void acpi_sleep(uint8_t sleep_state);

#endif // ACPI_H
