# Cairo OS
# Ahmed Hussein (amhussein4@gmail.com)
# February 28th 2024

# Generate RISC-V 32-bit, not compressed, instructions
.option norvc

.section .trampoline_section

.global trampoline

trampoline:
	mul a0,a0,a1
