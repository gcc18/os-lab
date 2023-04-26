ARCH ?= x86
TAG ?= 5.15.108
LOCAL_NAME ?= -gucd
CONFIG ?= kernel/kernel_config.x86

export KDIR = $(shell realpath $(PWD)/kernel/linux-$(TAG))
export KCONFIG = $(KDIR)/.config

KURL = https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-$(TAG).tar.gz
KIMAGE = $(KDIR)/arch/$(ARCH)/boot/bzImage

YOCTO_URL = https://downloads.yoctoproject.org/releases/yocto/yocto-4.1.3/machines/qemu/qemu$(ARCH)
YOCTO_IMAGE = core-image-minimal-qemu$(ARCH).ext4

HDA_IMAGE = hda.ext4

TEMPDIR := $(shell mktemp -u)

boot: $(KIMAGE) $(HDA_IMAGE)
	mkdir $(TEMPDIR)
	sudo mount -t ext4 -o loop $(HDA_IMAGE) $(TEMPDIR)
	sudo $(MAKE) -C $(KDIR) modules_install INSTALL_MOD_PATH=$(TEMPDIR)
	sudo umount $(TEMPDIR)
	rmdir $(TEMPDIR)

$(KIMAGE): $(KCONFIG)
	$(MAKE) -C $(KDIR) -j$(shell nproc)
	$(MAKE) -C $(KDIR) -j$(shell nproc) modules

$(KCONFIG):  $(KDIR)
	cp $(CONFIG) $(KDIR)/.config
	echo "\nCONFIG_LOCALVERSION=\"$(LOCAL_NAME)\"" >> $(KDIR)/.config
	$(MAKE) -C $(KDIR) olddefconfig
	$(MAKE) -C $(KDIR) mod2yesconfig

$(KDIR):
	wget -N  $(KURL) 
	tar -xvzf linux-$(TAG).tar.gz 


$(HDA_IMAGE): image/$(YOCTO_IMAGE)
	cp image/$(YOCTO_IMAGE) hda.ext4
	e2fsck -f hda.ext4
	resize2fs hda.ext4 64M

image/$(YOCTO_IMAGE):
	wget -N -P image $(YOCTO_URL)/$(YOCTO_IMAGE)


#
#     
#


skels:
	$(MAKE) -C labs skels

build: $(KIMAGE)
	$(MAKE) -C labs build

copy: $(HDA_IMAGE)
	mkdir $(TEMPDIR)
	sudo mount -t ext4 -o loop $(HDA_IMAGE) $(TEMPDIR)
	for i in $(shell find labs/skels -type f \( -name *.ko -or -executable \) | xargs --no-run-if-empty); do cp --parents -t $(TEMPDIR); done
	for i in $(shell find labs/skels -type d \( -name checker \) | xargs --no-run-if-empty); do cp --parents -t $(TEMPDIR); done
	sudo umount $(TEMPDIR)
	rmdir $(TEMPDIR)



.PHONY: build labs skels build