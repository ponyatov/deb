# HW     ?= pc
# HW     ?= qemu386
HW     ?= rpi3
# HW     ?= rpi4
# HW     ?= rpi5

include   hw/$(HW)/$(HW).mk
include  cpu/$(CPU)/$(CPU).mk
include arch/$(ARCH)/$(ARCH).mk
include   os/$(OS)/$(OS).mk
