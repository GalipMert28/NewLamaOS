#ifndef IOMMU_H
#define IOMMU_H

#include <system.h>
#include <stdint.h>
#include <stdbool.h>

// IOMMU Capabilities
#define IOMMU_CAP_COHERENT       0x00000001
#define IOMMU_CAP_WRITE_BUFFER   0x00000002
#define IOMMU_CAP_READ_BUFFER    0x00000004
#define IOMMU_CAP_PREFETCH       0x00000008
#define IOMMU_CAP_INVALIDATE     0x00000010
#define IOMMU_CAP_DIRECT_MAPPED  0x00000020
#define IOMMU_CAP_NESTED         0x00000040
#define IOMMU_CAP_PASID          0x00000080
#define IOMMU_CAP_PRI            0x00000100
#define IOMMU_CAP_ATS            0x00000200
#define IOMMU_CAP_SVA            0x00000400

// IOMMU Page Table Flags
#define IOMMU_PAGE_PRESENT       0x01
#define IOMMU_PAGE_WRITABLE      0x02
#define IOMMU_PAGE_USER          0x04
#define IOMMU_PAGE_WRITE_THROUGH 0x08
#define IOMMU_PAGE_CACHE_DISABLE 0x10
#define IOMMU_PAGE_ACCESSED      0x20
#define IOMMU_PAGE_DIRTY         0x40
#define IOMMU_PAGE_LARGE         0x80
#define IOMMU_PAGE_GLOBAL        0x100
#define IOMMU_PAGE_NO_EXECUTE    0x8000000000000000ULL

// IOMMU Domain Types
typedef enum {
    IOMMU_DOMAIN_IDENTITY = 0,
    IOMMU_DOMAIN_DMA,
    IOMMU_DOMAIN_UNMANAGED,
    IOMMU_DOMAIN_VIRTUAL,
} iommu_domain_type_t;

// IOMMU Device Structure
typedef struct iommu_device {
    uint8_t segment;
    uint8_t bus;
    uint8_t device;
    uint8_t function;
    uint16_t vendor_id;
    uint16_t device_id;
    uint64_t capabilities;
    uint64_t base_address;
    uint32_t version;
    struct iommu_device *next;
} iommu_device_t;

// IOMMU Domain Structure
typedef struct iommu_domain {
    iommu_domain_type_t type;
    uint64_t *page_table;
    uint64_t page_table_phys;
    uint32_t address_width;
    uint64_t dma_mask;
    uint32_t ref_count;
    struct iommu_device *iommu;
    void *private_data;
} iommu_domain_t;

// IOMMU Mapping Structure
typedef struct iommu_mapping {
    uint64_t virt_address;
    uint64_t phys_address;
    uint64_t size;
    uint64_t flags;
    iommu_domain_t *domain;
    struct iommu_mapping *next;
} iommu_mapping_t;

// DMA Address Translation Structure
typedef struct {
    uint64_t virt_address;
    uint64_t phys_address;
    uint64_t iova;
    uint64_t size;
    uint64_t flags;
} dma_translation_t;

// Function Prototypes
bool iommu_init(void);
iommu_device_t *iommu_get_devices(void);
uint32_t iommu_get_device_count(void);
iommu_domain_t *iommu_domain_alloc(iommu_domain_type_t type, uint64_t dma_mask);
void iommu_domain_free(iommu_domain_t *domain);
bool iommu_attach_device(iommu_domain_t *domain, iommu_device_t *device);
bool iommu_detach_device(iommu_domain_t *domain, iommu_device_t *device);
uint64_t iommu_map(iommu_domain_t *domain, uint64_t phys_addr, uint64_t size, uint64_t flags);
bool iommu_unmap(iommu_domain_t *domain, uint64_t iova, uint64_t size);
uint64_t iommu_virt_to_phys(iommu_domain_t *domain, uint64_t virt_addr);
uint64_t iommu_phys_to_virt(iommu_domain_t *domain, uint64_t phys_addr);
bool iommu_flush_tlb(iommu_domain_t *domain);
bool iommu_flush_cache(iommu_domain_t *domain);
bool iommu_set_dma_mask(iommu_domain_t *domain, uint64_t dma_mask);
uint64_t iommu_get_dma_mask(iommu_domain_t *domain);
bool iommu_device_supports_ats(iommu_device_t *device);
bool iommu_device_enable_ats(iommu_device_t *device);
bool iommu_device_disable_ats(iommu_device_t *device);
bool iommu_device_supports_pri(iommu_device_t *device);
bool iommu_device_enable_pri(iommu_device_t *device);
bool iommu_device_disable_pri(iommu_device_t *device);
bool iommu_device_supports_pasid(iommu_device_t *device);
bool iommu_device_enable_pasid(iommu_device_t *device, uint32_t pasid);
bool iommu_device_disable_pasid(iommu_device_t *device);
void iommu_dump_domain(iommu_domain_t *domain);
void iommu_dump_device(iommu_device_t *device);
void iommu_dump_all(void);

#endif // IOMMU_H
