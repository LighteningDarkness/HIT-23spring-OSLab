	.code16
# rewrite with AT&T syntax by falcon <wuzhangjin@gmail.com> at 081012
#
#	setup.s		(C) 1991 Linus Torvalds
#
# setup.s is responsible for getting the system data from the BIOS,
# and putting them into the appropriate places in system memory.
# both setup.s and system has been loaded by the bootblock.
#
# This code asks the bios for memory/disk/other parameters, and
# puts them in a "safe" place: 0x90000-0x901FF, ie where the
# boot-block used to be. It is then up to the protected mode
# system to read them from there before the area is overwritten
# for buffer-blocks.
#

# NOTE! These had better be the same as in bootsect.s!

	.equ INITSEG, 0x9000	# we move boot here - out of the way
	.equ SYSSEG, 0x1000	# system loaded at 0x10000 (65536).
	.equ SETUPSEG, 0x9020	# this is the current segment
	.global _start, begtext, begdata, begbss, endtext, enddata, endbss
	.text
	begtext:
	.data
	begdata:
	.bss
	begbss:
	.text

	ljmp $SETUPSEG, $_start	
_start:
	mov %cs,%ax
	mov %ax,%ds
	mov %ax,%es

	mov	$0x03, %ah		# read cursor pos
	xor	%bh, %bh
	int	$0x10
	
	mov	$28, %cx
	mov	$0x0007, %bx		# page 0, attribute 7 (normal)
	#lea	msg2, %bp
	mov     $msg2, %bp
	mov	$0x1301, %ax		# write string, move cursor
	int	$0x10
	

# get cursor position
	mov $INITSEG,%ax
    mov %ax,%ds
    mov $0x03,%ah
    xor %bh,%bh
    int $0x10 
	mov %dx,%ds:0x0

# print cursor hint info
	mov %ds:0x0,%dx
	mov	$0x03, %ah		
	xor	%bh, %bh
	int	$0x10
	mov	$11, %cx
	mov	$0x0007, %bx		
	mov     $msg3, %bp
	mov	$0x1301, %ax		
	int	$0x10
	call print_hex

# get memory size
    mov $0x88,%ah
    int $0x15                        
    mov %ax,%ds:0x2

# print hint info
	mov	$0x03, %ah		
	xor	%bh, %bh
	int	$0x10
	mov	$14, %cx
	mov	$0x0007, %bx		
	mov     $msg4, %bp
	mov	$0x1301, %ax		
	int	$0x10
	mov %ds:0x2,%dx
	call print_hex
	mov	$0x03, %ah		
	xor	%bh, %bh
	int	$0x10
	mov	$6, %cx
	mov	$0x0007, %bx		
	mov     $msg5, %bp
	mov	$0x1301, %ax		
	int	$0x10

# get hard disk parameters
    mov $0x0000,%ax
    mov %ax,%ds
    # lds si,[4*0x41]
	mov %ds:4*0x41,%si
	mov %ds:4*0x41+2,%ds        
    mov $INITSEG,%ax
    mov %ax,%es
    mov $0x0004,%di
    mov $0x10,%cx                    
    rep
    movsb 
# get prepared
    mov %cs,%ax
    mov %ax,%es
    mov $INITSEG,%ax
    mov %ax,%ds
# print hard disk info
	mov	$0x03, %ah		
	xor	%bh, %bh
	int	$0x10
	mov	$9, %cx
	mov	$0x0007, %bx		
	mov     $msg9, %bp
	mov	$0x1301, %ax		
	int	$0x10
# print cyls
	mov	$0x03, %ah		
	xor	%bh, %bh
	int	$0x10
	mov	$10, %cx
	mov	$0x0007, %bx		
	mov     $msg6, %bp
	mov	$0x1301, %ax		
	int	$0x10
	mov %ds:0x4,%dx
	call print_hex
# print heads
	mov	$0x03, %ah		
	xor	%bh, %bh
	int	$0x10
	mov	$8, %cx
	mov	$0x0007, %bx		
	mov     $msg7, %bp
	mov	$0x1301, %ax		
	int	$0x10
	mov %ds:0x6,%dx
	call print_hex
# print sectors
#	mov	$0x03, %ah		
#	xor	%bh, %bh
#	int	$0x10
#	mov	$10, %cx
#	mov	$0x0007, %bx		
#	mov     $msg8, %bp
#	mov	$0x1301, %ax		
#	int	$0x10
#	mov %ds:0x18,%dx
#	call print_hex
# infinite loop, just keeping displaying...
inf_loop:
    jmp inf_loop
# function of printing
print_hex:
    mov $4,%cx                   
print_digit:
    rol    $4,%dx                    
    mov    $0xe0f,%ax                
    and    %dl,%al                    
    add    $0x30,%al             
    cmp    $0x3a,%al                
    jl     outp                     
    add    $0x7,%al                
outp:
    int    $0x10                     
    loop   print_digit            
    ret   


msg2:
	.byte 13,10
	.ascii "Now we are in SETUP..."
	.byte 13,10,13,10
msg3:
	.ascii "Cursor POS:"

msg4:
	.byte 13,10
	.ascii "Memory Size:"
msg5:
	.ascii "KB"
	.byte 13,10,13,10
msg6:
    .ascii "Cylinders:"
msg7:
    .byte 13,10
    .ascii "Heads:"
msg8:
    .byte 13,10
    .ascii "Sectors:"
msg9:
    .ascii "HD Info"
	.byte 13,10

	.org 508
boot_flag:
    .word 0xAA55
.text
endtext:
.data
enddata:
.bss
endbss:
