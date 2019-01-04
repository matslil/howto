Instructions below assumes a newly installed Ubuntu server 17.04.

Firmware for Hauppauge HVR-2205
===============================

    sudo curl --insecure https://raw.githubusercontent.com/OpenELEC/dvb-firmware/master/firmware/dvb-demod-si2168-b40-01.fw -o /lib/firmware/dvb-demod-si2168-b40-01.fw
    sudo curl --insecure https://raw.githubusercontent.com/OpenELEC/dvb-firmware/master/firmware/NXP7164-2010-04-01.1.fw -o /lib/firmware/NXP7164-2010-04-01.1.fw40-01.fw
    mv /lib/firmware/firmware/NXP7164-2010-03-10.1.fw /lib/firmware/firmware/NXP7164-2010-03-10.1.fw.original
    ln -s /lib/firmware/NXP7164-2010-04-01.1.fw /lib/firmware/firmware/NXP7164-2010-03-10.1.fw

Add package repositories
========================

For latest version of KODI:

    sudo apt-add-repository ppa:team-xbmc/ppa

For latest version of TV headend:

    sudo apt-add-repository ppa:mamarley/tvheadend-git-stable

For a vast selection of emulators:

    sudo apt-add-repository ppa:libretro/stable

For latest version of Emulation Station:

    sudo apt-add-repository ppa:emulationstation/ppa

For Steam:

    sudo apt-add-repository ppa:dolphin-emu/ppa

Update package list:

    sudo apt update

Create Kodi user
================

    sudo adduser --disabled-password --disabled-login --gecos "" --home /mnt/kodi_home --no-create-home kodi
    sudo usermod -a -G audio,video,input,dialout,plugdev,tty,netdev kodi
    sudo usermod -a -G videokodi
    sudo usermod -a -G input kodi
    sudo usermod -a -G dialout kodi
    sudo usermod -a -G plugdev kodi
    sudo usermod -a -G tty kodi
    sudo pkg-reconfigure x11-common # Change to Anybody

Netowrk mount
=============

    sudo cat <<EOF | sudo tee /etc/systemd/system/mnt-kodi_home.mount
    [Unit]
    Description=cifs mount script
    Requires=network-online.target
    After=network-online.target
    Before=kodi.service
    [Mount]
    What=//192.168.1.4/kodi
    Where=/mnt/kodi_home
    Options=username=kodi,password=pwd,rw,uid=kodi,gid=kodi
    Type=cifs
    [Install]
    WantedBy=multi-user.target
    EOF

    sudo systemctl daemon-reload
    sudo systemctl enable mnt-kodi_home.mount

Install Kodi
============

    sudo apt install kodi

Make sure the file /etc/systemd/system/default.target.wants/kodi-autologin.service is a link to /lib/systemd/system/ureadahead.service, otherwise use "sudo systemctl enable kodi-autologin.service". The linked to file should have the following content:

    [Unit]
    Description=Read required files in advance
    DefaultDependencies=false
    Conflicts=shutdown.target
    Before=shutdown.target
    Requires=ureadahead-stop.timer
    RequiresMountsFor=/var/lib/ureadahead
    ConditionVirtualization=no

    [Service]
    ExecStart=/sbin/ureadahead
    # when profiling, give it three minutes after sending SIGTERM to write out the pack file
    TimeoutStopSec=3m

    [Install]
    WantedBy=default.target

Start Kodi in X-server
======================

    sudo apt install openbox

Setup scripts for starting Kodi in X-windows:

    cd
    wget -O openbox-kodi-master.zip https://github.com/lufinkey/kodi-openbox/archive/master.zip
    sudo apt install unzip
    unzip openbox-kodi-master.zip
    cd kodi-openbox-master
    bash ./build.sh
    sudo dpkg -i kodi-openbox.deb

Start X-windows when logging in into Kodi account:

    sudo su kodi
    cat > ~/.bash_profile <<EOF
    [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && exec startx
    EOF

Try Kodi
========

To iron out problems, run Kodi before rebooting:

    sudo service kodi start

Install C64 Emulator
====================

This one needs to be built from sources, didn't find an Ubuntu package for it.

1) Install needed tools for the build

    sudo apt-get install subversion bison flex libreadline-dev libxaw7-dev libpng-dev xa65 texinfo libpulse-dev texi2html libpcap-dev dos2unix libgtk2.0-cil-dev libgtkglext1-dev libvte-dev libvte-dev libavcodec-dev libavformat-dev libswscale-dev libmp3lame-dev libmpg123-dev yasm ffmpeg libx264-dev build-essential autoconf

2) Download repository

    mkdir -p ~/svn
    cd ~/svn
    svn co https://svn.code.sf.net/p/vice-emu/code/trunk/vice/

3) Do build

    cd vice
    ./autogen.sh
    ./configure --enable-fullscreen --with-pulse --with-x --enable-vte --enable-cpuhistory --with-resid --enable-external-ffmpeg
    make

4) Install

    sudo make install

Installing PlayStation 2 Emulator
=================================

1) Install

    sudo apt install pcsx2

Installing EmulationStation, RetroArch and Steam
================================================

    sudo apt install emulationstation* steam
   
