#########################
# Makefile for Orange'S #
#########################

# Entry point of Orange'S
# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT	= 0x30400

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
# 程序的入口地址
ENTRYOFFSET	=   0x400

# Programs, flags, etc.
ASM		= nasm
DASM	= ndisasm
CC		= gcc
LD		= ld
ASMBFLAGS	= -I boot/include/
ASMKFLAGS	= -I include/ -f elf
CFLAGS		= -I include/ -m32 -c -fno-builtin
# CFLAGS		= -I include/ -c -fno-builtin
LDFLAGS		= -m elf_i386 -s -Ttext $(ENTRYPOINT)
# LDFLAGS		= -s -Ttext $(ENTRYPOINT)
DASMFLAGS	= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# This Program
ORANGESBOOT		= boot/boot.bin boot/loader.bin
ORANGESKERNEL	= kernel.bin
OBJS			= kernel/kernel.o kernel/start.o lib/kliba.o lib/string.o
DASMOUTPUT		= kernel.bin.asm

# All Phony Targets
.PHONY : everything final image clean realclean disasm all buildimg

# Default starting position
everything : $(ORANGESBOOT) $(ORANGESKERNEL)

all : realclean everything

final : all clean

image : final buildimg

# 删除obj文件
clean :
	rm -f $(OBJS)

# 彻底清除
realclean :
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

# 反汇编
disasm :
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)


# We assume that "a.img" exists in current folder
buildimg :
	dd if=/dev/zero of=diska.img bs=512 count=2880
	dd if=boot/boot.bin of=a.img bs=512 count=1
	dd if=diska.img of=a.img skip=1 seek=1 bs=512 count=2879
	rm diska.img
	# 挂载
	sudo mount ./a.img /media/ -t vfat -o loop
	sudo cp -fv boot/loader.bin /media/
	sudo cp -fv kernel.bin /media/
	# sudo sync	#强制被改变的命令立刻写入软盘
	sudo umount /media/
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

	# dd if=boot/boot.bin of=a.img bs=512 count=1 conv=notrunc
	# sudo mount -o loop a.img /media/
	# sudo cp -fv boot/loader.bin /media/
	# sudo cp -fv kernel.bin /media/
	# sudo umount /media/

boot/boot.bin : boot/boot.asm boot/include/load.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/load.inc \
			boot/include/fat12hdr.inc boot/include/pm.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

$(ORANGESKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $(ORANGESKERNEL) $(OBJS)

kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/type.h include/const.h include/protect.h
	$(CC) $(CFLAGS) -o $@ $<

lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

# nasm -i /include -f -elf -o lib/string.o lib/string.asm

