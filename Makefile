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
# .deb cache
MM_OPTS  += --skip=update
MM_OPTS  += --skip=essential/unlink --skip=cleanup/apt
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
MM_OPTS  += --include=git,make,curl,mc
MM_OPTS  += --include=linux-image-$(KERNEL_VER)
MM_MIRROR = /etc/apt/sources.list

MM_OPTS  += --dpkgopt='path-exclude=/usr/share/{doc,info,man,locale}/*'

.PHONY: mmdeb
mmdeb:
	sudo rm -rf $(ROOT)
	sudo mmdebstrap $(MM_OPTS) $(MM_SUITE) $(ROOT) $(MM_MIRROR)

.PHONY: iso

SYSLINUX_FILES += $(ROOT)/boot/isohdpfx.bin $(ROOT)/boot/isolinux.bin

$(ROOT)/boot/%: /usr/lib/ISOLINUX/%
	sudo cp %< %@

iso: $(SYSLINUX_FILES) $(FW)/$(MODULE).iso
# https://wiki.syslinux.org/wiki/index.php?title=Isohybrid

.PHONY: $(FW)/$(MODULE).iso
$(FW)/$(MODULE).iso: $(SYSLINUX_FILES)
	sudo xorriso -as mkisofs -o $@ \
		-isohybrid-mbr $(ROOT)/boot/isohdpfx.bin \
		-c boot/isolinux.cat -b /boot/isolinux.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		$(ROOT)

.PHONY: qemu
qemu: $(FW)/$(MODULE).iso
	qemu-system-x86_64 -cdrom $< -boot d

# merge

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
