### Cairo OS
### Ahmed Hussein (amhussein4@gmail.com)
### Feb 28th 2024

import os
import sys
import pathlib

# Define compilers, assemblers, linkers and flags
assembler = "riscv64-elf-as"
c_compiler = "riscv64-elf-gcc"
c_flags = "-ffreestanding -nostdlib"
linker = "riscv64-elf-ld"

# Define locations of source files
source_path = "./src/"
link_script = "./src/link.ld"

# Define output and output location for object files
object_path = "./objects"
output = "cairo.elf"

# Collect all sources
asm_sources = []
c_sources = []
if(os.path.exists(source_path)):
	source_dir = pathlib.Path(source_path)
	dirlist = list(source_dir.rglob("*"))
	for item in dirlist:
		if(item.is_file()):
			filename = str(item)
			if(filename.find(".s") > 0):
				asm_sources.append(filename)

if(os.path.exists(source_path)):
	source_dir = pathlib.Path(source_path)
	dirlist = list(source_dir.rglob("*"))
	for item in dirlist:
		if(item.is_file()):
			filename = str(item)
			if(filename.find(".c") > 0):
				c_sources.append(filename)

# Create object output directory
if(not os.path.exists(object_path)):
	command_string = "mkdir " + object_path
	os.system(command_string)

def compile_asm():
	for source in asm_sources:
		raw_name = source[:-2]
		source_path = raw_name + ".s"
		target_path = raw_name + ".o"
		command_string = assembler + " " + source_path + " -o " + target_path
		print(command_string)
		os.system(command_string)
		command_string = "mv " + target_path + " " + object_path
		os.system(command_string)

def compile_c():
	for source in c_sources:
		raw_name = source[:-2]
		source_path = raw_name + ".c"
		target_path = raw_name + ".o"
		command_string = c_compiler + " " + c_flags + " -c " + source_path + " -o " + target_path
		print(command_string)
		os.system(command_string)
		command_string = "mv " + target_path + " " + object_path
		os.system(command_string)

def link():
	objects = ""
	object_dir = pathlib.Path(object_path)
	dirlist = list(object_dir.rglob("*"))
	for item in dirlist:
		if(item.is_file()):
			filename = str(item)
			if(filename.find(".o") > 0):
				objects = objects + " " + filename
	command_string = linker + " -T" + link_script + " " + objects + " -o " + output
	print(command_string)
	os.system(command_string)

def clean():
	command_string = "rm -f " + output
	os.system(command_string)
	command_string = "rm -f " + object_path + "/*.o"
	os.system(command_string)

def build():
	compile_asm()
	compile_c()
	link()

if(len(sys.argv) > 1):
	if(sys.argv[1] == "clean"):
		clean()
else:
	build()
