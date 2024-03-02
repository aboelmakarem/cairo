# Cairo OS
# Ahmed Hussein (amhussein4@gmail.com)
# February 28th 2024

# Define the architecture we are generating this for
OUTPUT_ARCH("riscv")

# Set the entry point to "entry" which is defined in entry.s
ENTRY(entry)

# Define all program sections
SECTIONS
{
	# Set current memory location to where RISC-V systems load their 
	# kernels at address 0x80000000
	. = 0x80000000;
	PROVIDE(memory_start = .);
	# let kernel program memory size be 4 GB
	PROVIDE(memory_length = 4294967296);
	# Program code
	.text : 
	{
		PROVIDE(text_start = .);
		# put the entry text first before anything else
		*(.text.entry)
		*(.text .text.*)
		# align the trampoline code to a 4-KB page boundary
		. = ALIGN(4096);
		# define trampoline location in physical memory
		PROVIDE(trampoline_start = .);
		# put trampoline code
		*(.trampoline_section)
		# give trampoline code its own full page, whatever comes next should 
		# start at the beginning of the next page
		. = ALIGN(4096);
		# verify that trampoline code does not exceed one page
		ASSERT(. - trampoline_start == 4096,"error: trampoline code is more than one page long");
		# define the end of text location
		PROVIDE(text_end = .);
	}

	# Define global pointer to be the first byte in the data 
	# section. This will be used in the assembly code to set the 
	# global pointer register and refer to instructions by their 
	# offset from global pointer. 
	PROVIDE(global_pointer = .);

	# Program read-only data
	.rodata : 
	{
		PROVIDE(rodata_start = .);
		*(.srodata .srodata.*)
		*(.rodata .rodata.*)
		PROVIDE(rodata_end = .);
	}

	# Program initialized read/write data
	.data : 
	{
		# Align this section to a 16-byte boundary
		. = ALIGN(16);
		PROVIDE(data_start = .);
		*(.sdata .sdata.*)
		*(.data .data.*)
		PROVIDE(data_end = .);
	}

	# Program uninitialized data
	.bss : 
	{
		# Align this section to a 16-byte boundary
		. = ALIGN(16);
		PROVIDE(bss_start = .);
		*(.sbss .sbss.*)
		*(.bss .bss.*)
		PROVIDE(bss_end = .);
	}

	# Define the memory location where heap and stack can be 
	# allocated. These will be calculated based on the currently 
	# set memory start location. Calculate the memory end location 
	# from the previously defined memory called ram. 
	PROVIDE(memory_end = memory_start + memory_length);
	# Let the kernel stack start at the end of the BSS section. 
	# Because stack grows downwards, the end of the kernel stack 
	# section needs to be calculated. Allocate 512 KB for the 
	# kernel stack. Each RISC-V hart will take one 4-KB page 
	# to use as its kernel stack space. This allows for up 
	# to 128 harts to be operating in parallel. 
	PROVIDE(kernel_stack_start = bss_end);
	PROVIDE(kernel_stack_end = kernel_stack_start + 0x80000);
	# The kernel heap region is all the space above the stack and 
	# all the way up to the end of memory
	PROVIDE(heap_start = kernel_stack_end);
	PROVIDE(heap_end = memory_end);
	PROVIDE(heap_size = heap_end - heap_start);
}
