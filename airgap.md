% Air-Gap Computer Howto
% Mats G. Liljegren

About this howto
================

This is a guide how to create an ISO image to be run on a computer that is
not connected to the network, which is called an air-gap computer.

These instructions assume Ubuntu Linux, and was tested on Ubuntu 15.04.

Preparing host
==============

On host:

To be able to ssh into the virtual machine later on, install openssh-server on host:

    sudo apt-get install --yes openssh-server

Create the virtual machine:

    sudo apt-get install virt-install

Download Ubuntu 15.10 i386 to ~/Downloads

```
mkdir ~/vm-airgap
cd ~/vm-airgap
virt-install -n vm-airgap --memory 2048 --cdrom ~/Downloads/ubuntu-15.10-desktop-i386.iso \
--disk ~/vm-airgap/vm-airgap.qcow2,size=24,format=qcow2 --network network=default
```

On virtual machine:
 -  Answer install questions
 -  Reboot
 -  Open terminal window

```
sudo apt-get install --yes debootstrap
sudo apt-get install --yes syslinux squashfs-tools genisoimage isolinux
mkdir -p ~/work/chroot
cd ~/work
sudo debootstrap wily chroot
```

Setup change root environment
=============================

```
sudo cp /etc/hosts chroot/etc/hosts
sudo cp /etc/resolv.conf chroot/etc/resolv.conf
sudo mount --bind /dev chroot/dev
sudo chroot chroot
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C
```

Preparing root file system
==========================

```
# Install add-apt-repository tool
apt-get install --yes software-properties-common

# Add needed repositories
apt-add-repository ppa:yubico/stable
add-apt-repository "deb http://archive.ubuntu.com/ubuntu wily universe"
apt-get update

# DBUS configuration
dbus-uuidgen > /var/lib/dbus/machine-id

dpkg-divert --local --rename --add /sbin/initctl

# Install base OS
apt-get install --yes ubuntu-standard casper lupin-casper
apt-get install --yes discover laptop-detect os-prober
apt-get install --yes linux-generic

# Install yubikey tools
apt-get install --yes yubikey-personalization-gui yubikey-neo-manager 
apt-get install --yes yubikey-personalization python-pkg-resources ykneomgr

# Install GPG2, since it has better smart card support
# Install pcscd, scdaemon and pscs-tools for smart card support
# Install paperkey to translate GPG key to printable text file
# Install haveged to improve entropy generation
apt-get install --yes pcscd scdaemon gnupg2 pcsc-tools paperkey haveged

# Install X-server support using xfce4 window manager, needed by some yubikey tools
apt-get install --yes xserver-xorg xserver-xorg-core xfonts-base xinit x11-xserver-utils
apt-get install --yes xfwm4 xfce4-panel xfce4-settings xfce4-session xfce4-terminal
apt-get install --yes xfdesktop4 xfce4-taskmanager tango-icon-theme lightdm
apt-get install --yes lightdm-gtk-greeter

# Force gpg2
ln -s /usr/bin/gpg2 /usr/local/bin/gpg

# Add ubuntu user, used as guest account with sudo privilege
adduser --gecos ubuntu --disabled-password ubuntu
adduser ubuntu sudo
passwd -d ubuntu

# Make login welcome message the same for local and network logins
rm /etc/issue.net
ln -s /etc/issue /etc/issue.net

# Add text to login welcome message
echo "Use 'ubuntu' as user name to login." >> /etc/issue
```

Cleanup root file system
========================

```
rm /var/lib/dbus/machine-id
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/*
rm /etc/resolv.conf
umount -lf /sys
umount -lf /dev/pts
umount -lf /proc
exit
```

Back at the host:

    sudo umount -lf ${HOME}/work/chroot/dev

Create boot files
=================

```
# Create directory hierarchy
mkdir -p image/{casper,isolinux,install}

# Copy files needed for booting
sudo cp chroot/boot/vmlinuz-*-generic image/casper/vmlinuz
sudo cp chroot/boot/initrd.img-*-generic image/casper/initrd.lz
cp /usr/lib/ISOLINUX/isolinux.bin /usr/lib/syslinux/modules/bios/ldlinux.c32 \
image/isolinux/
cp /boot/memtest86+.bin image/install/memtest

# Create boot welcome message
echo <<EOF > image/isolinux/isolinux.txt
************************************************************************

This is an Ubuntu Remix Live CD.

For the default live system, enter "live".  To run memtest86+, enter "memtest"

************************************************************************
EOF

# Create boot configuration file, similar but not identical with how GRUB is configured
echo <<EOF > image/isolinux/isolinux.cfg
DEFAULT live
LABEL live
  menu label ^Start or install Ubuntu Remix
  kernel /casper/vmlinuz
  append  file=/cdrom/preseed/ubuntu.seed boot=casper initrd=/casper/initrd.lz quiet --
LABEL check
  menu label ^Check CD for defects
  kernel /casper/vmlinuz
  append  boot=casper integrity-check initrd=/casper/initrd.lz quiet --
LABEL memtest
  menu label ^Memory test
  kernel /install/memtest
  append -
DISPLAY isolinux.txt
TIMEOUT 300
PROMPT 1
EOF
```

Make the squashfs image from the root file system
=================================================

```
# Create a manifest file with package names and version, removing packages
# not needed for hard-disk installation
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee \
image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper lupin-casper '\
'live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
for i in $REMOVE 
do
        sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done

# Get total size of root file system
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

# Make sure we start fresh
rm -f image/casper/filesystem.squashfs

# Make the sqaushfs image
sudo mksquashfs chroot image/casper/filesystem.squashfs -e boot
```

Prepare ISO meta files
======================

```
# Describe ISO image to be created
echo <<EOF > image/README.diskdefines
#define DISKNAME  Ubuntu Remix
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  i386
#define ARCHi386  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

# Files needed if ISO image is to be installed on USB
touch image/ubuntu
mkdir image/.disk
touch image/.disk/base_installable
echo "full_cd/single" > image/.disk/cd_type
echo "Ubuntu Remix 15.10" > image/.disk/info
echo "http://your-release-notes-url.com" > image/.disk/release_notes_url
```

Create ISO image
================

```
sudo -- sh -c 'cd image && find . -type f -print0 | xargs -0 md5sum | grep -v \
"\./md5sum.txt" > md5sum.txt'

(cd image && sudo mkisofs -r -V "air-gap" -cache-inodes -J -l -b isolinux/isolinux.bin -c \
isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../air-gap.iso .)
```

Testing the image
=================

Copy the image to the host:

```
scp ${USER}@<ip-to-vm>:~/work/air-gap.iso ~/
virt-install --cdrom ~/air-gap.iso --name air-gap --memory 2048 --nodisk
```

When finished testing:

```
virsh destroy air-gap
virsh undefine air-gap
rm -f ~/air-gap.iso
```

References
==========

* https://help.ubuntu.com/community/LiveCDCustomizationFromScratch
* https://www.sidorenko.io/blog/2014/11/04/yubikey-slash-openpgp-smartcards-for-newbies
* https://xpressubuntu.wordpress.com/2014/02/22/how-to-install-a-minimal-ubuntu-desktop/

License
=======

![](license-icon-88x31.png)

Copyright (C) 2016, Mats G. Liljegren

This work is licensed under a Creative Commons Attribution 4.0 International License.

