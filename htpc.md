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

Define Kodi service
===================

    sudo cat <<EOF | sudo tee /etc/systemd/system/kodi.service
    [Unit]
    Description=Job that runs Kodi
    After=default.target graphical.target getty.target sound.target mnt-kodi_home.mount
    [Service]
    User=kodi
    Restart=always
    RestartSec=1s
    ExecStart=/usr/bin/xinit /usr/bin/kodi --standalone -- -nocursor
    [Install]
    WantedBy=default.target
    EOF

    sudo systemctl daemon-reload
    sudo systemctl enable kodi

Work-Around for X-windows
=========================

For Ubuntu 16.04 the following is needed to work-around permission problems:

    sudo apt-get install xserver-xorg-legacy
    sudo dpkg-reconfigure xserver-xorg-legacy

Choose "Anybody".

    cat <<EOF | sudo tee -a /etc/X11/Xwrapper.config
    needs_root_rights=yes
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
    ./configure --enable-fullscreen --with-pulse --enable-vte --enable-cpuhistory --with-resid --enable-external-ffmpeg
    make

4) Install

    sudo make install

Installing PlayStation 2 Emulator
=================================

1) Install

    sudo apt-get install pcsx2

Installing EmulationStation, RetroArch and Steam
================================================

Instructions followed: https://github.com/BrosMakingSoftware/Kodi-Launches-EmulationStation-Addon

1) Add repositories for emulator and Steam support

    sudo apt-add-repository ppa:libretro/stable
    sudo apt-add-repository ppa:emulationstation/ppa
    sudo apt-add-repository ppa:dolphin-emu/ppa
    sudo apt-get update

2) Install emulators, EmulationStation and Steam

    
