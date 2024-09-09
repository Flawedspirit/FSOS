SRC_DIR=src
BUILD_DIR=build

.PHONY: all bootloader kernel clean always

# MAIN IMAGE
main: $(BUILD_DIR)/twsos.img
$(BUILD_DIR)/twsos.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/twsos.img bs=512 count=2880
	mkfs.fat -F 12 -n "TWSOS" $(BUILD_DIR)/twsos.img
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/twsos.img conv=notrunc
	mcopy -i $(BUILD_DIR)/twsos.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

# BOOTLOADER
bootloader: $(BUILD_DIR)/boot.bin
$(BUILD_DIR)/boot.bin: always
	nasm $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/boot.bin

# KERNEL
kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	nasm $(SRC_DIR)/kernel/kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

clean:
	rm -rf $(BUILD_DIR)/*

always:
	mkdir -p $(BUILD_DIR)

run:
	qemu-system-x86_64 -drive format=raw,file=$(BUILD_DIR)/twsos.img