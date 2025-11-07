# live-boot

- https://habr.com/ru/articles/242219/
- **https://gist.github.com/ravecat/63a0d49014b6187bebc68cf855d55a83**

## `huawei/any/any.mk`

https://manpages.debian.org/unstable/live-boot-doc/live-boot.7.en.html

host:
```
dbus live-build
```
target:
```Makefile
MM_OPTS  += --include=init,dbus,live-boot
MM_OPTS  += --include=linux-image-$(DEB_CPU),linux-headers-$(DEB_CPU)
MM_OPTS  += --include=firmware-linux-free,firmware-linux-nonfree
```
