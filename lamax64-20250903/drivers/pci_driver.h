#ifndef PCI_DRIVER_H
#define PCI_DRIVER_H

#include <system.h>
#include <stdint.h>
#include <stdbool.h>

// PCI Constants
#define PCI_MAX_DEVICES         256
#define PCI_MAX_RESOURCES       16
#define PCI_MAX_CAPABILITIES    32
#define PCI_MAX_MSI_VECTORS     32
#define PCI_MAX_MSIX_VECTORS    2048
#define PCI_MAX_SRIOV_VFS       256

// PCI Address Constants
#define PCI_ADDRESS_SPACE_IO    0x01
#define PCI_ADDRESS_SPACE_MEM   0x00
#define PCI_ADDRESS_MEM_64BIT   0x04
#define PCI_ADDRESS_MEM_PREFETCH 0x08

// PCI Power Management States
typedef enum {
    PCI_PM_D0 = 0,      // Full power
    PCI_PM_D1,          // Low power
    PCI_PM_D2,          // Lower power
    PCI_PM_D3,          // Lowest power (off)
    PCI_PM_D3COLD,      // Cold D3
} pci_pm_state_t;

// PCI Resource Types
typedef enum {
    PCI_RESOURCE_IO = 0,
    PCI_RESOURCE_MEMORY,
    PCI_RESOURCE_PREFETCH,
    PCI_RESOURCE_ROM,
    PCI_RESOURCE_BUS,
} pci_resource_type_t;

// PCI Capability Structure
typedef struct pci_capability {
    uint8_t id;
    uint8_t offset;
    uint16_t version;
    uint32_t data[8];
    struct pci_capability *next;
} pci_capability_t;

// MSI Information
typedef struct {
    bool supported;
    bool enabled;
    bool is_64bit;
    uint8_t offset;
    uint8_t multiple_message_capable;
    bool per_vector_masking;
    uint32_t base_vector;
    uint32_t num_vectors;
    uint64_t address;
    uint32_t data;
} msi_info_t;

// MSI-X Information
typedef struct msix_table_entry {
    uint32_t msg_addr_low;
    uint32_t msg_addr_high;
    uint32_t msg_data;
    uint32_t vector_control;
} msix_table_entry_t;

typedef struct {
    bool supported;
    bool enabled;
    uint16_t offset;
    uint16_t table_size;
    uint16_t table_offset;
    uint8_t table_bir;
    uint16_t pba_offset;
    uint8_t pba_bir;
    uint32_t base_vector;
    msix_table_entry_t *table_virt;
    uint64_t *pba_virt;
} msix_info_t;

// DMA Coherency Information
typedef struct {
    bool supported;
    bool enabled;
    uint32_t coherency_domain;
    uint64_t dma_mask;
} dma_coherency_t;

// SR-IOV Information
typedef struct {
    bool supported;
    bool enabled;
    uint16_t offset;
    uint16_t num_vfs;
    uint16_t initial_vfs;
    uint16_t vf_offset;
    uint16_t vf_stride;
    uint32_t vf_device_id;
    uint8_t cap_version;
    uint16_t first_vf_offset;
    uint16_t vf_migration_state;
} sriov_info_t;

// AER (Advanced Error Reporting) Information
typedef struct {
    bool supported;
    bool enabled;
    uint16_t offset;
    uint32_t uncorrectable_error_mask;
    uint32_t uncorrectable_error_severity;
    uint32_t correctable_error_mask;
    uint32_t advanced_cap_control;
    uint32_t root_command;
    uint32_t root_status;
} aer_info_t;

// Hotplug Information
typedef struct {
    bool supported;
    bool enabled;
    uint8_t offset;
    uint8_t cap_version;
    uint16_t slot_capabilities;
    uint16_t slot_control;
    uint16_t slot_status;
} hotplug_info_t;

// PCIe Link Information
typedef struct {
    bool is_pcie;
    uint8_t cap_offset;
    uint8_t pcie_cap_version;
    uint8_t device_type;
    uint8_t link_speed;
    uint8_t link_width;
    uint16_t link_status;
    uint16_t link_control;
    uint32_t slot_capabilities;
    uint32_t slot_control;
    uint32_t root_control;
} pcie_link_info_t;

// PCI Resource
typedef struct {
    pci_resource_type_t type;
    uint64_t base;
    uint64_t size;
    uint32_t flags;
    bool allocated;
} pci_resource_t;

// PCI Performance Counters
typedef struct {
    uint64_t read_ops;
    uint64_t write_ops;
    uint64_t dma_transfers;
    uint64_t interrupts;
    uint64_t errors;
    uint64_t retries;
} pci_perf_counters_t;

// Base PCI Device Structure
typedef struct pci_device {
    uint8_t bus;
    uint8_t slot;
    uint8_t function;
    uint16_t vendor_id;
    uint16_t device_id;
    uint16_t command;
    uint16_t status;
    uint8_t revision_id;
    uint8_t prog_if;
    uint8_t subclass;
    uint8_t class_code;
    uint8_t cache_line_size;
    uint8_t latency_timer;
    uint8_t header_type;
    uint8_t bist;
    uint16_t subsys_vendor_id;
    uint16_t subsys_device_id;
    uint32_t bars[6];
    uint32_t cardbus_cis;
    uint16_t vendor_specific[2];
    uint32_t rom_address;
    uint8_t interrupt_line;
    uint8_t interrupt_pin;
    uint8_t min_grant;
    uint8_t max_latency;
} pci_device_t;

// PCI Driver Structure
typedef struct pci_driver {
    char name[32];
    uint16_t vendor_id;
    uint16_t device_id;
    uint8_t class_code;
    uint8_t subclass;
    uint8_t prog_if;
    bool (*probe)(pci_device_t *device);
    bool (*remove)(pci_device_t *device);
    void (*suspend)(pci_device_t *device);
    void (*resume)(pci_device_t *device);
    void (*shutdown)(pci_device_t *device);
    void *private_data;
} pci_driver_t;

// PCI System Structure
typedef struct {
    bool initialized;
    bool pcie_supported;
    bool iommu_enabled;
    bool acpi_enabled;
    uint8_t num_buses;
    uint32_t device_count;
    uint64_t ecam_base;
    uint64_t ecam_size;
    uint32_t msi_base_vector;
    uint32_t msix_base_vector;
} pci_system_t;

// Function Prototypes
void pci_init(void);
void pci_scan_all(void);
pci_device_t *pci_find_device(uint16_t vendor_id, uint16_t device_id);
pci_device_t *pci_find_class(uint8_t class_code, uint8_t subclass, uint8_t prog_if);
uint32_t pci_read_config32(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset);
void pci_write_config32(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset, uint32_t value);
uint32_t pcie_read_config32(uint8_t bus, uint8_t slot, uint8_t func, uint16_t offset);
void pcie_write_config32(uint8_t bus, uint8_t slot, uint8_t func, uint16_t offset, uint32_t value);
bool pci_register_driver(pci_driver_t *driver);
bool pci_unregister_driver(pci_driver_t *driver);
void pci_enable_device(pci_device_t *device);
void pci_disable_device(pci_device_t *device);
void pci_set_master(pci_device_t *device, bool enable);
uint64_t pci_get_bar_address(pci_device_t *device, uint8_t bar_index);
uint64_t pci_get_bar_size(pci_device_t *device, uint8_t bar_index);
bool pci_allocate_resource(pci_device_t *device, uint8_t bar_index);
void pci_free_resource(pci_device_t *device, uint8_t bar_index);
bool pci_setup_msi(pci_device_t *device, uint32_t vector_count);
bool pci_setup_msix(pci_device_t *device, uint32_t vector_count);
void pci_disable_msi(pci_device_t *device);
void pci_disable_msix(pci_device_t *device);
bool pci_set_power_state(pci_device_t *device, pci_pm_state_t state);
pci_pm_state_t pci_get_power_state(pci_device_t *device);
void pci_reset_device(pci_device_t *device);
bool pci_enable_sriov(pci_device_t *device, uint16_t num_vfs);
void pci_disable_sriov(pci_device_t *device);
void pci_enable_aer(pci_device_t *device);
void pci_disable_aer(pci_device_t *device);
void pci_handle_error(pci_device_t *device);
void pci_dump_device(pci_device_t *device);
void pci_dump_all_devices(void);

// IRQ Handler Type
typedef void (*pci_irq_handler_t)(pci_device_t *device, uint32_t irq);

#endif // PCI_DRIVER_H
