Based on https://github.com/zfsonlinux/zfs/wiki/Ubuntu-16.04-Root-on-ZFS

Preparations
============

Download Ubuntu 16.04 desktop.

    wget http://releases.ubuntu.com/16.04/ubuntu-16.04-desktop-amd64.iso

Insert USB memory. Use dmesg to determine its device name.
Write image to an USB memory.

    sudo dd if=ubuntu-16.04-desktop-amd64.iso of=<USB device> bs=4096

Insert USB memory, usually works best with the USB connectors attached on the motherboard.
When booting, you might need to enter BIOS setup and make sure it boots from the USB memory.
On my motherboard I sometimes need to detach and re-attach the USB memory when the message about no bootable memory appears. Then press return. Not sure if this is a security feature or something...
Select "Try Ubuntu" (Tab + Return)
Open terminal (Ctrl-Alt-T)
Get openssh server:

    sudo apt-get install --yes openssh-server
    passwd (current password is empty)
    ip addr

Now SSH to the box using IP and password above:

    ssh ubuntu@<IP>

Get tools
=========

    sudo -i
    apt-add-repository universe
    apt-get update
    apt-get install --yes debootstrap gdisk

Make UEFI partitions
====================

    find /dev/disk/by-id/ -name 'ata-*'

Assign the corresponding SSD disks to SSD1 and SSD2 environment variables, likewise with the SATA1 and SATA2 disks:

    export SSD1=<first SSD disk full name, i.e. starting at />
    export SSD2=<second SSD disk full name>
    export SATA1=<first SATA hard disk full name>
    export SATA2=<second SATA hard disk full name>

    sgdisk     --clear               $SSD1
    kpartx -u $SSD1
    sgdisk     -n3:1M:+512M -t3:EF00 $SSD1
    sgdisk     -n9:-8M:0    -t9:BF07 $SSD1
    sgdisk     -n1:0:0      -t1:BF01 $SSD1

    sgdisk     --clear               $SSD2
    kpartx -u $SSD2
    sgdisk     -n3:1M:+512M -t3:EF00 $SSD2
    sgdisk     -n9:-8M:0    -t9:BF07 $SSD2
    sgdisk     -n1:0:0      -t1:BF01 $SSD2

Make root and home pools
========================

Root uses two SSD drives in mirroring mode, home uses two harddiscs also in mirroring mode.
Disabling "hole_birth" since it has had so many issues. This is done by disabling all features and then enabling all but hole_birth feature.

Note: If you have had a ZFS partition it might auto-mount when installing zfs-initramfs!
      Check this with "mount | fgrep zfs", and use "zfs unmount <partition>" to unmount.

    apt-get install --yes zfs-initramfs
    zpool list -Ho name | xargs zpool destroy
    zpool create -o ashift=12 \
      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
      -O mountpoint=/ -R /mnt \
      -d -o feature@async_destroy=enabled \
         -o feature@empty_bpobj=enabled \
         -o feature@filesystem_limits=enabled \
         -o feature@lz4_compress=enabled \
         -o feature@spacemap_histogram=enabled \
         -o feature@extensible_dataset=enabled \
         -o feature@bookmarks=enabled \
         -o feature@enabled_txg=enabled \
         -o feature@embedded_data=enabled \
         -o feature@large_blocks=enabled \
      rpool mirror ${SSD1}-part1 ${SSD2}-part1
    zpool create -o ashift=12 \
      -O atime=off -O canmount=off -O compression=lz4 -O setuid=off \
      -O mountpoint=/home -R /mnt \
      -d -o feature@async_destroy=enabled \
         -o feature@empty_bpobj=enabled \
         -o feature@filesystem_limits=enabled \
         -o feature@lz4_compress=enabled \
         -o feature@spacemap_histogram=enabled \
         -o feature@extensible_dataset=enabled \
         -o feature@bookmarks=enabled \
         -o feature@enabled_txg=enabled \
         -o feature@embedded_data=enabled \
         -o feature@large_blocks=enabled \
      hpool mirror $SATA1 $SATA2

Make ZFS datasets
=================

Properties (-o) are inherited. Entries with "canmount=off" are only for specifying properties common to all child datasets.

    zfs create -o canmount=off -o mountpoint=none         rpool/ROOT
    zfs create -o canmount=noauto -o mountpoint=/         rpool/ROOT/ubuntu
    zfs mount rpool/ROOT/ubuntu
    zfs create -o canmount=on -o mountpoint=/home         hpool/home
    zfs create -o mountpoint=/root -o setuid=off          rpool/home-root
    zfs create -o canmount=off -o setuid=off  -o exec=off rpool/var
    zfs create -o com.sun:auto-snapshot=false             rpool/var/cache
    zfs create                                            rpool/var/log
    zfs create                                            rpool/var/spool
    zfs create -o com.sun:auto-snapshot=false -o exec=on  rpool/var/tmp
    zfs create                                            rpool/var/mail
    zfs create -o com.sun:auto-snapshot=false -o mountpoint=/var/lib/nfs rpool/var/nfs

Install minimal system
======================

    chmod 1777 /mnt/var/tmp
    debootstrap xenial /mnt
    zfs set devices=off rpool hpool

System configuration
====================

    SERVERNAME=fserver
    echo $SERVERNAME > /mnt/etc/hostname
    cat <<EOF >> /mnt/etc/hosts
    127.0.1.1       $SERVERNAME
    EOF
    cat <<EOF > /mnt/etc/network/interfaces.d/eno1
    auto eno1
    iface eno1 inet dhcp
    EOF
    mount --rbind /dev  /mnt/dev
    mount --rbind /proc /mnt/proc
    mount --rbind /sys  /mnt/sys
    chroot /mnt /bin/bash --login
    locale-gen en_US.UTF-8
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale
    dpkg-reconfigure tzdata
    cat <<EOF >> /etc/apt/sources.list
    deb http://archive.ubuntu.com/ubuntu xenial main universe
    deb-src http://archive.ubuntu.com/ubuntu xenial main universe

    deb http://security.ubuntu.com/ubuntu xenial-security main universe
    deb-src http://security.ubuntu.com/ubuntu xenial-security main universe

    deb http://archive.ubuntu.com/ubuntu xenial-updates main universe
    deb-src http://archive.ubuntu.com/ubuntu xenial-updates main universe
    EOF
    ln -s /proc/self/mounts /etc/mtab
    apt-get update
    apt-get install --yes ubuntu-minimal

Install ZFS in the chroot environment for the new system
========================================================

    apt-get install --yes --no-install-recommends linux-image-generic
    apt-get install --yes zfs-initramfs

Groups and root password
========================

    addgroup --system lpadmin
    addgroup --system sambashare
    passwd

Install GRUB UEFI
=================

    apt-get install --yes dosfstools
    mkdosfs -F 32 -n EFI ${SSD1}-part3
    mkdosfs -F 32 -n EFI ${SSD2}-part3
    mkdir /boot/efi /boot/efi-mirror
    cat <<EOF >> /etc/fstab
    PARTUUID=$(blkid -s PARTUUID -o value ${SSD1}-part3) /boot/efi vfat defaults 0 1
    PARTUUID=$(blkid -s PARTUUID -o value ${SSD2}-part3) /boot/efi-mirror vfat defaults 0 1
    EOF
    mount /boot/efi
    mount /boot/efi-mirror
    apt-get install --yes grub-efi-amd64

    grub-probe /

Verify that output is "zfs"

    update-initramfs -c -k all
    vi /etc/default/grub

Comment out GRUB_HIDDEN_TIMEOUT=0
Remove quiet and splash from GRUB_CMDLINE_LINUX_DEFAULT
Uncomment GRUB_TERMINAL=console
Add "GRUB_DISABLE_OS_PROBER=true"
Save and quit.

    update-grub
    grub-install --target=x86_64-efi --efi-directory=/boot/efi        --bootloader-id=ubuntu --recheck --no-floppy
    grub-install --target=x86_64-efi --efi-directory=/boot/efi-mirror --bootloader-id=ubuntu --recheck --no-floppy

Reboot
======

    exit
    mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | xargs -i{} umount -lf {}
    zpool export rpool hpool
    reboot

Go into BIOS configuration and make sure you boot from "UEFI:Ubuntu".

Create administrator account
============================

    zfs create hpool/home/mats
    adduser --gecos "Mats" mats
    cp -a /etc/skel/.[!.]* /home/mats
    chown -R mats:mats /home/mats
    usermod -a -G adm,cdrom,dip,lpadmin,plugdev,sambashare,sudo mats

Upgrade to full distribution
============================

    apt-get dist-upgrade --yes
    apt-get install --yes ubuntu-standard ubuntu-server openssh-server

At this point, it is possible to ssh into the machine again, making copy'n paste working.

Disable log compression
=======================

Since ZFS does compression already.

    sudo -i
    for file in /etc/logrotate.d/* ; do
        if grep -Eq "(^|[^#y])compress" "$file" ; then
            sed -i -r "s/(^|[^#y])(compress)/\1#\2/" "$file"
        fi
    done
    reboot

Create other accounts
=====================

    sudo -i
    zfs create hpool/home/gemensamt
    adduser --disabled-login --gecos "gemensamt" gemensamt
    chgrp gemensamt /home/gemensamt
    chmod 0775 /home/gemensamt
    for name in <space separated list of users>; do
      zfs create hpool/home/$name
      adduser --gecos "$name" --disabled-login $name
      chown -R $name:$name /home/$name # Only if adduser complains about ownership!
      smbpasswd -a $name
      usermod -a $name -G gemensamt
    done

The above steps can also be applied for special accounts, e.g. kodi account for htpc setup. In that case, skip the "usermod" (last step), since those special accounts does not need access to gemensamt directory.

ZFS snapshots
=============

    zfs snapshot -r rpool@install
    zfs snapshot -r hpool@install

Remove root password
====================

    sudo usermod -p '*' root

Make etc versioned
==================

    cd /etc
    git init
    cat <<EOF > .gitignore
    *-
    *~
    *.lock
    EOF
    git config --global user.email "<your e-mail address>"
    git config --global user.name "<your name>"
    git add .
    git commit -m "Newly installed"

Install Samba
=============

    chmod 0775 /home/gemensamt
    sudo apt-get install --yes samba
    (cd /etc && git add . && git commit -m "Samba installed")
    vi /etc/samba/smb.conf
    (cd /etc && git commit samba/smb.conf -m "Samba configured")
    testparm
    service samba reload


Install TLP for power save
==========================

    apt-get install --yes linux-tools-generic smartmontools
    apt-get install --no-install-recommends --yes tlp
    (cd /etc && git add . && git commit -m "TLP installed")
    vi /etc/default/tlp

Edit power saving values!

    (cd /etc && git commit default/tlp -m "TLP configured")
    tlp start
    systemctl stop smartmontools

Todo: This is done since smartmontools otherwise prohibit power-safe from occurring.
      Should be replaced with a cron-job!

Harden the server
=================

Install firewall

    ufw delete 1
    ufw allow OpenSSH
    ufw allow Samba
    ufw enable

Make /run/shm read-only:

    cat <<EOF >> /etc/fstab
    tmpfs     /run/shm     tmpfs     ro,nosuid,nodev,noexec     0     0
    EOF

Hard disk failure detection
===========================

Make script that checks hard disk status:

    mkdir ~/bin
    cat > ~/bin/weekly.sh <<EOF
    #!/bin/sh -eu

    DEVICES="sdc sdd"

    for dev in $DEVICES; do
      sudo /usr/sbin/smartctl -l error /dev/$dev
    done
    EOF

Edit CRON table for current user to run this service at a weekly basis:

    crontab -e

Add following lines:

    MAILTO="<mail address>"
    @weekly $HOME/bin/weekly.sh

Make sure current user can run this script with root privilege without password:

    cat <<EOF | sudo tee /etc/sudoers.d/smartctl-$USER > /dev/null
    # Allow $USER to run smartctl as root without password, so cron job does not need to run with root privileges
    $USER ALL = (root) NOPASSWD: /usr/sbin/smartctl
    EOF

As mentioned above when installing TLP for power save, there is no monitoring of disks about to fail.

   smartctl --quietmode=errorsonly --log=error

Add backup USB disk
===================

Adding a USB disk that can be used for backup. Uses ZFS on it, and snapshots to handle backup versions.

Insert a USB disk. Use `dmesg | tail` to get which device that got assigned to the disk. This device is from now called `<dev>`.

    sudo zpool create pool <dev>
    sudo zfs create pool/backup

To make a backup, use:

    sudo rsync --archive --info=progress2 --numeric-ids --no-whole-file --inplace --xattrs --hard-links  --delete /home/mats /home/gemensamt /pool/backup/
    sudo zfs snapshot pool/backup@$(date +%Y-%m-%d_%H:%M)

