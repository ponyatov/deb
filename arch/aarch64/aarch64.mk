OS      = linux
TARGET  = aarch64-linux-gnu
APT    += qemu-system-arm gcc-aarch64-linux-gnu gdb-multiarch
QEMU    = qemu-system-aarch64
MM     += --arch=arm64 --include=libc6:arm64
# MM     += linux-image-arm64
