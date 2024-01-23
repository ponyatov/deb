# var
MODULE  = $(notdir $(CURDIR))
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# version
D_VER        = 2.106.1
KERNEL_VER   = $(shell uname -r)
BUSYBOX_VER  = 1.36.1
SYSLINUX_V   = 6.04
SYSLINUX_VER = $(SYSLINUX_V)-pre1

# dir
CWD  = $(CURDIR)
BIN  = $(CWD)/bin
SRC  = $(CWD)/src
TMP  = $(CWD)/tmp
GZ   = $(HOME)/gz
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
BUSYBOX     = busybox-$(BUSYBOX_VER)
BUSYBOX_GZ  = $(BUSYBOX).tar.bz2

SYSLINUX    = syslinux-$(SYSLINUX_VER)
SYSLINUX_GZ = $(SYSLINUX).tar.xz

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
gz: $(DC) $(DUB) \
	$(GZ)/$(BUSYBOX_GZ)

$(DC) $(DUB): $(HOME)/distr/SDK/dmd_$(D_VER)_amd64.deb
	sudo dpkg -i $< && sudo touch $(DC) $(DUB)
$(HOME)/distr/SDK/dmd_$(D_VER)_amd64.deb:
	$(CURL) $@ https://downloads.dlang.org/releases/2.x/$(D_VER)/dmd_$(D_VER)-0_amd64.deb

$(GZ)/$(BUSYBOX_GZ):
	$(CURL) $@ https://busybox.net/downloads/$(BUSYBOX_GZ)

.PHONY: bb bbconfig
bb: $(ROOT)/bin/busybox
	cd $(REF)/$(BUSYBOX) ; make menuconfig ;\
	make -j$(CORES) && make install
$(ROOT)/bin/busybox: $(REF)/$(BUSYBOX)/.config

$(REF)/$(BUSYBOX)/.config: $(REF)/$(BUSYBOX)/README.md
	git checkout $@
bbconfig:
	rm -f $(REF)/$(BUSYBOX)/.config
	cd $(REF)/$(BUSYBOX) ; make CONFIG_PREFIX=$(ROOT) allnoconfig ;\
	make menuconfig

.PHONY: syslinux
syslinux: $(REF)/$(SYSLINUX)/README.md
	rm -rf $(TMP)/syslinux ; mkdir -p $(TMP)/syslinux
	cd $(REF)/$(SYSLINUX) ; LD='ld --no-warn-rwx-segments' make V=1 O=$(TMP)/syslinux -j$(CORES) bios

$(GZ)/$(SYSLINUX_GZ):
	$(CURL) $@ https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/Testing/$(SYSLINUX_V)/$(SYSLINUX_GZ)

.PHONY: mmdeb
mmdeb:
	sudo mmdebstrap --variant=custom --include=busybox-static stable $(ROOT)/mmdeb /etc/apt/sources.list

# merge

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
