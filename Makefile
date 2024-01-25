# var
MODULE  = $(notdir $(CURDIR))
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# version
D_VER        = 2.106.1
KERNEL_VER   = $(shell uname -r)

# dir
CWD  = $(CURDIR)
BIN  = $(CWD)/bin
SRC  = $(CWD)/src
TMP  = $(CWD)/tmp
GZ   = $(HOME)/gz
FW   = $(CWD)/fw
REF  = $(CWD)/ref
ROOT = $(CWD)/root

# tool
CURL = curl -L -o
DC   = /usr/bin/dmd
DUB  = /usr/bin/dub
RUN  = $(DUB) run   --compiler=$(DC)
BLD  = $(DUB) build --compiler=$(DC)
DPKG = dpkg --install --root $(ROOT)

# src
D += $(wildcard src/*.d*)
D += $(wildcard init/src/*.d*)

# package

# all
.PHONY: all
all: $(ROOT)/sbin/init
	file $< ; echo ; ldd $<
	sudo chroot $(ROOT) /bin/sh
$(ROOT)/sbin/init: $(D) dub.json Makefile
	$(BLD) :init && chmod +x $@

.PHONY: fw
fw: kernel modules $(ROOT)/bin/busybox

.PHONY: kernel
kernel: $(ROOT)/boot/vmlinuz-$(KERNEL_VER) $(ROOT)/boot/config-$(KERNEL_VER)
$(ROOT)/boot/%-$(KERNEL_VER): /boot/%-$(KERNEL_VER)
	cp $< $@

.PHONY: modules
MODULES = lib/modules/$(KERNEL_VER)
modules: $(ROOT)/$(MODULES)/modules.dep
$(ROOT)/$(MODULES)/modules.dep: /$(MODULES)/modules.dep
	mkdir -p $(ROOT)/lib/modules ; mkdir -p $(ROOT)/$(MODULES)
	cp    /$(MODULES)/modules* $(ROOT)/$(MODULES)/
	cp -r /$(MODULES)/kernel   $(ROOT)/$(MODULES)/
	cp -r /$(MODULES)/misc     $(ROOT)/$(MODULES)/
	touch $@

# format
format: tmp/format_d
tmp/format_d: $(D)
	$(RUN) dfmt -- -i $? && touch $@

# rule
bin/$(MODULE): $(D) Makefile
	$(BLD)

$(REF)/%/README.md: $(GZ)/%.tar.bz2
	cd $(REF) ; bzcat $< | tar x && touch $@
$(REF)/%/README.md: $(GZ)/%.tar.xz
	cd $(REF) ; xzcat $< | tar x && touch $@

# doc
.PHONY: doc
doc: doc/yazyk_D.pdf doc/Programming_in_D.pdf

doc/yazyk_D.pdf:
	$(CURL) $@ https://www.k0d.cc/storage/books/D/yazyk_programmirovaniya_d.pdf
doc/Programming_in_D.pdf:
	$(CURL) $@ http://ddili.org/ders/d.en/Programming_in_D.pdf

# install
.PHONY: install update gz
install: doc gz
	$(MAKE) update
	dub build dfmt
update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`
gz: $(DC) $(DUB)

$(DC) $(DUB): $(HOME)/distr/SDK/dmd_$(D_VER)_amd64.deb
	sudo dpkg -i $< && sudo touch $(DC) $(DUB)
$(HOME)/distr/SDK/dmd_$(D_VER)_amd64.deb:
	$(CURL) $@ https://downloads.dlang.org/releases/2.x/$(D_VER)/dmd_$(D_VER)-0_amd64.deb


MM_SUITE  = bookworm
MM_TARGET = $(ROOT)
MM_MIRROR = http://mirror.mephi.ru/debian/
MM_OPTS  += --setup-hook='git checkout cache/.gitignore "$$1"/.gitignore'
MM_OPTS  += --customize-hook='git checkout "$$1"'
# .deb cache
# --skip=cleanup/apt
MM_OPTS  += --skip=update --skip=essential/unlink
MM_OPTS  += --setup-hook='mkdir -p ./cache ./cache/archives ./cache/lists'
MM_OPTS  += --setup-hook='mkdir -p "$$1"/var/cache/apt/archives'
MM_OPTS  += --setup-hook='mkdir -p "$$1"/var/lib/apt/lists'
MM_OPTS  += --setup-hook='sync-in  ./cache/archives /var/cache/apt/archives'
MM_OPTS  += --setup-hook='sync-in  ./cache/lists    /var/lib/apt/lists'
MM_OPTS  += --customize-hook='apt update && apt upgrade -y'
MM_OPTS  += --customize-hook='sync-out /var/cache/apt/archives ./cache/archives'
MM_OPTS  += --customize-hook='sync-out /var/lib/apt/lists      ./cache/lists'
MM_OPTS  += --customize-hook='sync-out /root                   ./cache/root'
# MM_OPTS  += --architectures=native
# native
# amd64
MM_OPTS  += --variant=minbase
# minbase
# custom
# extract
MM_OPTS  += --include=git,make,curl,mc,vim
MM_OPTS  += --include=linux-image-$(KERNEL_VER)
MM_MIRROR = /etc/apt/sources.list

MM_OPTS  += --dpkgopt='path-exclude=/usr/share/{doc,info,man,locale}/*'

.PHONY: root
root:
	sudo rm -rf $(ROOT)
	sudo mmdebstrap $(MM_OPTS) $(MM_SUITE) $(ROOT) $(MM_MIRROR)

.PHONY: boot
SYSLINUX_FILES += $(ROOT)/isolinux/isohdpfx.bin $(ROOT)/isolinux/isolinux.bin
SYSLINUX_FILES += $(ROOT)/isolinux/ldlinux.c32 $(ROOT)/isolinux/ls.c32
boot: $(SYSLINUX_FILES)
$(ROOT)/isolinux/%: /usr/lib/ISOLINUX/%
	sudo cp $< $@
$(ROOT)/isolinux/%: /usr/lib/syslinux/modules/bios/%
	sudo cp $< $@

.PHONY: iso
iso: $(FW)/$(MODULE).iso
.PHONY: $(FW)/$(MODULE).iso
$(FW)/$(MODULE).iso: $(SYSLINUX_FILES)
# https://wiki.syslinux.org/wiki/index.php?title=Isohybrid
	sudo xorriso -as mkisofs -o $@ \
		-partition_offset 16 -A $(MODULE) \
		-isohybrid-mbr $(ROOT)/isolinux/isohdpfx.bin \
		-c isolinux/isolinux.cat -b /isolinux/isolinux.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		$(ROOT)

.PHONY: qemu
qemu:
	qemu-system-x86_64 -m 512m -cdrom $(FW)/$(MODULE).iso -boot d

.PHONY: usb
USB=null
usb:
	sudo dmesg | grep $(USB)
	sudo chown $(USER) /dev/$(USB) ; ls -la /dev/$(USB)
	/sbin/fdisk -l /dev/$(USB)
	/sbin/fdisk    /dev/$(USB)
	sudo chown $(USER) /dev/$(USB)*
# 
# dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/$(USB)
# /sbin/mkfs.vfat -v /dev/$(USB)1 -i DeadBeef -n $(MODULE)
# syslinux -i /dev/$(USB)1
	mcopy -i /dev/$(USB)1 -o syslinux.cfg ::
# mcopy -i /dev/$(USB)1 -o /boot/vmlinuz-$(KERNEL_VER) ::
# mcopy -i /dev/$(USB)1 -o /boot/initrd.img-$(KERNEL_VER) ::
	mdir  -i /dev/$(USB)1
# sudo mkfs.ext3 -v /dev/$(USB)2 -L B00bCafe -d $(ROOT)
	qemu-system-x86_64 -m 1G -hdc /dev/$(USB) -boot c

# merge

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
