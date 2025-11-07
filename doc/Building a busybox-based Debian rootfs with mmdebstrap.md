# Building a [[Buildroot/busybox|busybox]]-based [[Debian/Debian|Debian]] [[rootfs]] with [[mmdebstrap]]

- [video](https://youtu.be/UrDlUWNNkDY?si=KCpoQnr3qOw_NOTu)

![[Pasted image 20241012124938.png]]

## MM_SUITE

- `MM_SUITE=bookworm` [[Debian/Debian#12]]

## --architectures

- `MM_OPTS+= --architectures=i386` [[Debian/Debian#i386]]

## --variant

- `MM_OPTS+= --variant=minbase`

## run

```shell
mmdebstrap $(MM_OPTS) $(MM_SUITE) root $(MM_MIRROR)
```

[[Debian/Live|Live]]