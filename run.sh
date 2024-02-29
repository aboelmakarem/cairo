
qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 4G -serial mon:stdio -bios none -kernel cairo.elf -drive if=none,format=raw,file=hdd.dsk,id=foo -device virtio-blk-device,scsi=off,drive=foo
