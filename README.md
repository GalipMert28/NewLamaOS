# LamaX Operating System v1.0.0
## **LamaX, Unix benzeri komutlara sahip 64-bit ve 32-bit bir işletim sistemidir.**
## **🚀 Özellikler**

* **64-bit and 32-bit Architecture: Modern x86_64 mimarisi desteği**
* **Multi-stage Boot:**
* **MBR → Disk Loader(lamadiskfs64) → Shell(lamabootfs) → Kernel(x64-20250902 Versiyonları İçin)**
* **MBR -> Disk Loader(lamadiskfs) -> Bootloader -> Protected Mode -> Kernel(x86-20250902 Versiyonları İçin)**
* **Hybrid Commands: Windows ve Linux komutlarının karışımı(x64-20250902 Versiyonları İçin)**
* **Unix-like CLI: Komut satırı arayüzü**
* **VGA Text Mode: Renkli terminal çıktısı**
* **Memory Management: Temel bellek yönetimi**
* **Process Simulation: Süreç simülasyonu**

# *📋 Sistem Gereksinimleri*
**Derleme için:**

* GCC (32-bit desteği)
* NASM (Netwide Assembler)
* GNU ld (Linker)
* GNU objcopy


Test için:

QEMU (önerilen)
VirtualBox (alternatif)

