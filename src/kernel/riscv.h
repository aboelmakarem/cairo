/// Cairo OS
/// Ahmed Hussein (amhussein4@gmail.com)
/// Jan 29th 2024

#ifndef RISCV_H_
#define RISCV_H_

#include "types.h"

/// Status Bit Masks
#define MSTATUS_MPP			(3L << 11)
#define MSTATUS_MPP_M		(3L << 11)
#define MSTATUS_MPP_S		(1L << 11)
#define MSTATUS_MIE			(1L << 3)

#define SSTATUS_SPP			(1L << 8)
#define SSTATUS_SPIE		(1L << 5)
#define SSTATUS_SIE			(1L << 1)

/// Interrupt Enable Bit Masks
#define MIE_MSIE			(1L << 3)
#define MIE_MTIE			(1L << 7)
#define MIE_MEIE			(1L << 11)

#define SIE_SSIE			(1L << 1)
#define SIE_STIE			(1L << 5)
#define SIE_SEIE			(1L << 9)

/// Core identification
static inline u64 hart_id()
{
	u64 id = 0;
	asm volatile("csrr %0, mhartid" : "=r" (id));
	return id;
}

/// Status control
static inline u64 read_machine_status()
{
	u64 status = 0;
	asm volatile("csrr %0, mstatus" : "=r" (status));
	return status;
}

static inline void write_machine_status(u64 status)
{
	asm volatile("csrw mstatus, %0" : : "r" (status));
}

static inline u64 read_supervisor_status()
{
	u64 status = 0;
	asm volatile("csrr %0, sstatus" : "=r" (status));
	return status;
}

static inline void write_supervisor_status(u64 status)
{
	asm volatile("csrw sstatus, %0" : : "r" (status));
}

/// Global interrupt control
static inline void globally_disable_supervisor_interrupts()
{
	u64 status = read_supervisor_status();
	write_supervisor_status(status & ~(SSTATUS_SIE));
}

static inline void globally_enable_supervisor_interrupts()
{
	u64 status = read_supervisor_status();
	write_supervisor_status(status | SSTATUS_SIE);
}

static inline int supervisor_interrupts_globally_enabled()
{
	u64 status = read_supervisor_status();
	return (status & SSTATUS_SIE);
}

/// Trap enable control (see and control which traps 
/// are enabled)
static inline u64 get_machine_enabled_traps()
{
	u64 enabled = 0;
	asm volatile("csrr %0, mie" : "=r" (enabled));
	return enabled;
}

static inline void set_machine_enabled_traps(u64 enabled)
{
	asm volatile("csrw mie, %0" : : "r" (enabled));
}

static inline u64 get_supervisor_enabled_traps()
{
	u64 enabled = 0;
	asm volatile("csrr %0, sie" : "=r" (enabled));
	return enabled;
}

static inline void set_supervisor_enabled_traps(u64 enabled)
{
	asm volatile("csrw sie, %0" : : "r" (enabled));
}

/// Pending Traps
static inline u64 get_pending_traps()
{
	u64 pending = 0;
	asm volatile("csrr %0, sip" : "=r" (pending));
	return pending;
}

static inline void set_pending_traps(u64 pending)
{
	asm volatile("csrw sip, %0" : : "r" (pending));
}

/// Trap Delegation
static inline u64 get_machine_delegated_interrupts()
{
	u64 delegated;
	asm volatile("csrr %0, mideleg" : "=r" (delegated));
	return delegated;
}

static inline void set_machine_delegated_interrupts(u64 delegated)
{
	asm volatile("csrw mideleg, %0" : : "r" (delegated));
}

static inline u64 get_machine_delegated_exceptions()
{
	u64 delegated;
	asm volatile("csrr %0, medeleg" : "=r" (delegated));
	return delegated;
}

static inline void set_machine_delegated_exceptions(u64 delegated)
{
	asm volatile("csrw medeleg, %0" : : "r" (delegated));
}

/// Interrupt vector base address control
/// Low two bits of the mtvec and stvec registers give the trap 
/// vector mode (direct or vectorized)
static inline void set_machine_trap_vector_location(u64 location)
{
	asm volatile("csrw mtvec, %0" : : "r" (location));
}

static inline u64 get_supervisor_trap_vector_location()
{
	u64 location = 0;
	asm volatile("csrr %0, stvec" : "=r" (location));
	return location;
}

static inline void set_supervisor_trap_vector_location(u64 location)
{
	asm volatile("csrw stvec, %0" : : "r" (location));
}

/// Trap return address
static inline u64 get_machine_trap_return_location()
{
	u64 location = 0;
	asm volatile("csrr %0, mepc" : "=r" (location));
	return location;
}

static inline void set_machine_trap_return_location(u64 location)
{
	asm volatile("csrw mepc, %0" : : "r" (location));
}

static inline u64 get_supervisor_trap_return_location()
{
	u64 location = 0;
	asm volatile("csrr %0, sepc" : "=r" (location));
	return location;
}

static inline void set_supervisor_trap_return_location(u64 location)
{
	asm volatile("csrw sepc, %0" : : "r" (location));
}

/// Trap cause, value and scratch access
static inline u64 get_supervisor_trap_cause()
{
	u64 cause = 0;
	asm volatile("csrr %0, scause" : "=r" (cause));
	return cause;
}

static inline u64 get_supervisor_trap_value()
{
	u64 value = 0;
	asm volatile("csrr %0, stval" : "=r" (value));
	return value;
}

static inline void write_machine_scratch(u64 value)
{
	asm volatile("csrw mscratch, %0" : : "r" (value));
}

/// Counters, monitors and their control
static inline u64 get_machine_enabled_counters()
{
	u64 counters = 0;
	asm volatile("csrr %0, mcounteren" : "=r" (counters));
	return counters;
}

static inline void set_machine_enabled_counters(u64 counters)
{
	asm volatile("csrw mcounteren, %0" : : "r" (counters));
}

/// Thread pointer access
static inline u64 get_thread()
{
	u64 thread = 0;
	asm volatile("mv %0, tp" : "=r" (thread));
	return thread;
}

static inline void set_thread(u64 thread)
{
	asm volatile("mv tp, %0" : : "r" (thread));
}

/// Stack access
static inline u64 get_stack_location()
{
	u64 location = 0;
	asm volatile("mv %0, sp" : "=r" (location));
	return location;
}

/// Timer access and control
static inline u64 get_time()
{
	u64 time = 0;
	asm volatile("mv %0, mtime" : "=r" (time));
	return time;
}

/// Memory paging
typedef u64 pagetable_entry;
typedef u64* pagetable;

/// Sv39 Memory Paging
/// Sv39 Page Table Entry Masks
#define PTE_V 					(1L << 0)
#define PTE_R 					(1L << 1)
#define PTE_W 					(1L << 2)
#define PTE_X 					(1L << 3)
#define PTE_U 					(1L << 4)

/// Page size and page table entry access macros
#define PAGE_SIZE				4096
#define PAGE_SHIFT				12
#define PTE_FLAG_COUNT			10
#define PAGE_INDEX_MASK			0x1FF
#define PTE_FLAG_MASK			0x3FF

#define PAGE_ROUND_DOWN(size)	(size & ~(PAGE_SIZE - 1))
#define PAGE_ROUND_UP(size)		(PAGE_ROUND_DOWN(size + PAGE_SIZE - 1))

#define PAGE_INDEX_SHIFT(level)		(30 - 9*level)
#define PAGE_INDEX(level,address)	(((u64)(address) >> PAGE_INDEX_SHIFT(level)) & PAGE_INDEX_MASK)

#define PHYSICAL_ADDRESS(pte)				((pte >> PTE_FLAG_COUNT) << PAGE_SHIFT)
#define PTE_OF_PHYSICAL_ADDRESS(address)	((address >> PAGE_SHIFT) << PTE_FLAG_COUNT)
#define PTE_FLAGS(pte)						(pte & PTE_FLAG_MASK)

#define SV39_SATP					(8L << 60)
#define SATP_ROOT_ADDRESS(address)	(((u64)(address) >> PAGE_SHIFT) | SV39_SATP)

/// Supervisor-mode Page table base pointer
static inline u64 get_page_table_location()
{
	u64 location = 0;
	asm volatile("csrr %0, satp" : "=r" (location));
	return location;
}

static inline void set_page_table_location(u64 location)
{
	asm volatile("csrw satp, %0" : : "r" (location));
}

static inline void flush_tlb()
{
	asm volatile("sfence.vma zero, zero");
}

/// Maximum virtual address for a process, including kernel 
/// kernel process given an Sv39 paging scheme where every 
/// virtual address is 39 bits. Sv39 requires that the upper 
/// 25 bits of the 64-bit address be set to the same value 
/// as the 39th bit (the one right before them) or else, a 
/// page fault will occur. 
/// Here, we set the maximum virtual address to be half of 
/// the maximum possible value (the highest bit is always 
/// set to zero) in order to avoid having to sign extend the 
/// remaining 25 bits (out of a 64-bit address) in case the 
/// highest bit is 1. Still, with 38-bit address spaces, there 
/// is plenty of space (256 GB) for every process. 

#define MAX_VIRTUAL_ADDRESS					(1L << 38)

#endif

