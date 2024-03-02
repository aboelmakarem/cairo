# Cairo OS
# Ahmed Hussein (amhussein4@gmail.com)
# February 28th 2024

# Generate RISC-V 32-bit, not compressed, instructions
.option norvc

# Define a special text section for the boot code
.section .text.entry

# Make entry symbol global
.global entry

entry:
	# Initialize all machine and supervisor mode status registers
	# for all harts in the system
	# 1. zero (m/s)tval, (m/s)cause and (m/s)scratch
	csrw mtval,zero
	csrw stval,zero
	csrw mcause,zero
	csrw scause,zero
	csrw mscratch,zero
	csrw sscratch,zero
	# 2. Do not modify any of the event counters or the type of 
	# the events they count. The following registers
	# mcycle, minstret, mhpmcounter3 --> mhpmcounter31, 
	# mhpmevent3 --> mhpmevent31, cycle, time, instret, 
	# hpmcounter3 --> hpmcounter31
	# 3. Allow all counters to run by disabling all counter 
	# inhibitions
	#csrw mcountinhibit, zero
	# 4. Enable supervisor mode to read time and instret 
	# counters only
	li t0,0x07
	csrw mcounteren,t0
	# 5. Enable user mode to read time, cycle and instret 
	# counters only
	csrw scounteren,t0
	# 6. Clear and forget about all pending interrupts
	csrw mip,zero
	csrw sip,zero
	# 7. Clear page table base address register
	csrw satp,zero
	# 8. Delegate all exceptions and interrupts to supervisor mode 
	# for all harts
	li t1,0xffff
	csrw mideleg,t1
	csrw medeleg,t1
	# 9. Set the machine mode trap vector location and use the 
	# same location for supervisor mode trap vector
	la t2,trap_vector
	csrw mtvec,t2
	csrw stvec,t2
	# 10. Zero machine mode return address
	csrw mepc,zero
	csrw sepc,zero
	# 11. Set supervisor mode status to user-level and no interrupt 
	# handling for now
	csrw sstatus,zero
	# 12. Enable all traps in mie (timer, software and external)
	# for machine mode, this requires setting bits 3, 7 and 11
	# in mie register
	li t2,0x888
	csrw mie,t2
	# 13. Do the same for sie, but this requires setting bits 
	# 1, 5 and 9 instead. 
	li t2,0x0222
	csrw sie,t2
	# 14. Set machine mode status
	# bits 11 and 12: machine privilege level
	# bit 7: machine mode past interrupt enabled
	# bit 3: machine mode current interrupt enabled
	li t2,0x1888
	csrw mstatus,t2
	# 15. Allow supervisor mode to have full access to 
	# all memory. Set the physical memory protection (PMP) 
	# configuration register pmpcfg0 to give the first 
	# PMP range full access and set the first PMP range 
	# address register pmpaddr0 to point to the top of the 
	# accessible memory and have a memory size that is 
	# equal to all the accessible memory. 
	# The PMP configuration is 8 bits and a configutation 
	# of 0x0f allows read, write and execute access to 
	# a memory range that starts at memory 0 and ends at 
	# the memory address specified in PMP address register 
	# 0. 
	csrw pmpcfg0,0x0f
	# The top of the address range for PMP first range should 
	# be all the memory accessible to the hart. This is 
	# a 56-bit memory range that runs from 0 - 2**56. 
	# The value in pmpaddr0 should then be 2**56 - 1
	li t3,0xffffffffffffff
	csrw pmpaddr0,t3

	# Store the hart ID in tp
	csrr tp,mhartid
	# If this is not core 0, skip the section below and 
	# go to set the hart stack
	bnez tp,set_hart_stack

	# The following runs on hart 0 only
	# push the current options stack
	.option push
	# Do not relax instructions when loading global pointer. 
	# This way, addresses in instructions are not calculated 
	# based on a datum value in global pointer which still 
	# has not been set yet. 
	.option norelax
	# load the address at global_pointer to register gp
	# global_pointer is an address that is defined in the 
	# linker script. The global_pointer points to the end 
	# of the text section of the program
	la gp,global_pointer
	# pop back the options stack (get rid of last option)
	.option pop

	# Zero-out all BSS section. The symbols bss_start and 
	# bss_end are defined in the linker script and they 
	# point to the beginning and end of bss section
	la a0,bss_start
	la a1,bss_end
	bgeu a0,a1,set_hart_stack

	# loop over all bytes in BSS and set them to zero
bss_clear_loop:
	# write zero to the double word pointed to by the 
	# address in a0
	sd zero,(a0)
	# move to the next double word
	addi a0,a0,8
	# iterate
	bltu a0,a1,bss_clear_loop

set_hart_stack:
	# Set kernel stack pointer, each hart gets its own 
	# stack space equal to one page in memory. The linker 
	# defines where the kernel stack end is and it is 
	# designed to support up to 128 harts. All harts above 
	# 128, if they exist, will be put to permanent sleep 
	# and never used. 
	# Register tp holds the hart ID
	li t1,128
	bgeu tp,t1,upper_hart_sleep
	# load the kernel stack space start to sp
	la sp,kernel_stack_start
	# kernel stack size
	li a0,4096
	# 1-based hart id
	addi a1,tp,1
	# hart's kernel stack end offset
	mul a0,a0,a1
	# set hart stack end
	add sp,sp,a0
	
enter_kernel_main:
	# call the kernel main function, this call never returns
	call kernel_main

entry_spin:
	# Spin forever, this is never reached since the call to 
	# kernel_main never returns
	j entry_spin

upper_hart_sleep:
	# Sleep until woken up by an interrupt from another core
	wfi
	j upper_hart_sleep
