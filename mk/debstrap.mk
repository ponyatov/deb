MM_SUITE  = trixie
# MM_SUITE  = $(shell lsb_release -sc)
MM_MIRROR = etc/apt/$(MM_SUITE).sources.list

MM       += --variant=essential
# MM       += --variant=minbase

# MM       += --variant=extract
# MM       += --variant=custom
# MM       += --include=base-files,libc-bin,coreutils,dash,diffutils,sed,mawk
# MM       += --include=dpkg
# MM       += --include=apt,dpkg
# MM       += --include=init,live-boot
# MM       += --include=linux-image-amd64,linux-headers-amd64
# MM       += --include=firmware-linux-free,firmware-linux-nonfree
# --path-exclude
# --customize-hook='sync-in etc/network /etc/network'
# base-passwd,bash,
#     findutils,grep,gzip,sed,tar,

# --aptopt='Acquire::Check-Valid-Until "false"'
# --aptopt='Acquire::Languages { "environment"; "en"; }'
# --aptopt='Acquire::Languages "none"'
# --aptopt='Apt::Install-Recommends "true"'
# --aptopt='Acquire::http { Proxy "http://127.0.0.1:3142"; }'
# --aptopt='APT::Sandbox::User "root"'
# --dpkgopt="path-exclude=/usr/share/man/*"

.PHONY: root $(BIN)/$(APP)$(HW).tar
root: $(BIN)/$(APP)$(HW).tar
$(BIN)/$(APP)$(HW).tar:
	rm -rf root ; git checkout root
	mmdebstrap $(MM) $(MM_SUITE) --format=tar $@ $(MM_MIRROR) \
		--setup-hook='cp etc/hostname $$1/etc/'	\
		--setup-hook='cp etc/resolv.conf $$1/etc/' \
		--essential-hook='dpkg -l > etc/essential' 2> etc/log

# root/done: tmp/squid
# 	sudo mmdebstrap $(MM) $(MM_SUITE) root $(MM_MIRROR)

APT += mmdebstrap qemu-user-static guestfish
