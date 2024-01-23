# var
MODULE  = $(notdir $(CURDIR))
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# version
D_VER       = 2.106.1
KERNEL_VER  = $(shell uname -r)
BUSYBOX_VER = 1.36.1

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

# src
D += $(wildcard src/*.d*)
D += $(wildcard init/src/*.d*)

# package
BUSYBOX    = busybox-$(BUSYBOX_VER)
BUSYBOX_GZ = $(BUSYBOX).tar.bz2

# all
.PHONY: all
all: $(ROOT)/sbin/init
	file $< ; echo ; ldd $<
# sudo chroot $(ROOT) init
$(ROOT)/sbin/init: $(D) dub.json Makefile
	$(BLD) :init && chmod +x $@

.PHONY: fw
fw: \
	$(ROOT)/boot/vmlinuz-$(KERNEL_VER) \
	$(ROOT)/bin/busybox

$(ROOT)/boot/vmlinuz-$(KERNEL_VER): /boot/vmlinuz-$(KERNEL_VER)
	cp $< $@

# format
format: tmp/format_d
tmp/format_d: $(D)
	$(RUN) dfmt -- -i $? && touch $@

# rule
bin/$(MODULE): $(D) Makefile
	$(BLD)

$(REF)/%/README.md: $(GZ)/%.tar.bz2
	cd $(REF) ; bzcat $< | tar x && touch $@

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
	$(CURL) $@ https://busybox.net/downloads/busybox-1.36.1.tar.bz2

.PHONY: bb bbconfig
bb: $(ROOT)/bin/busybox
$(ROOT)/bin/busybox: $(REF)/$(BUSYBOX)/.config
	cd $(REF)/$(BUSYBOX) ; make menuconfig ;\
	make -j$(CORES) && make install

$(REF)/$(BUSYBOX)/.config: $(REF)/$(BUSYBOX)/README.md
	git checkout $@
bbconfig:
	rm -f $(REF)/$(BUSYBOX)/.config
	cd $(REF)/$(BUSYBOX) ; make CONFIG_PREFIX=$(ROOT) allnoconfig ;\
	make menuconfig

# merge

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
