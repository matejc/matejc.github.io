---
layout: post
title: Playing on QEMU/KVM
tags:
- linux
comments: true
---

Playing Witcher 3 on Linux inside a virtual machine (QEMU/KVM guest), with performance very close to host.


## Hardware

First of all you need CPU that supports hardware passthrough (I have _Intel i5-4670_) and motherboard must support IOMMU, please read [Prerequisites](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF)

You will need 2 graphic cards and preferably 2 sound cards.

One graphic card will be used by the host (integrated one) and the other will be for VM - I am using AMD Radeon RX480

The same goes for the sound cards - one for the host and the other one for VM - I am using USB ones. You could use just one and configure Pulseaudio to play audio from virtual machine, but I have 2 sets of speakers in the room so I gave passthrough of USB sound card a try.

For better performance I use SSD drive for storage directly and not images.

Also.. I am using the second monitor, mouse and keyboard just for virtual machine.


## Software

### Kernel Modules

I have following kernel modules loaded at boot time (not sure if all of them are needed): kvm-intel, kvm, pci_stub, vfio, vfio_pci, vfio_iommu_type1.

For the AMD CPUs, you will have different KVM module and not kvm-intel.


### Kernel parameters

Next two are not for AMD CPUs, replace the first one (google it), the second one might not be needed at all.

    intel_iommu=on
    i915.enable_hd_vgaarb=1


The following options are used for both platform (some just prevent random BSOD inside VM)

    vfio_iommu_type1.allow_unsafe_interrupts=1
    kvm.allow_unsafe_assigned_interrupts=1
    kvm.ignore_msrs=1


### Blacklist your second graphic card

You will need to blacklist graphic card (the one for the VM) module.
For my case I blacklisted _amdgpu_.


### Windows

I am using Windows 10, get it .. for example: buy it.


### OVMF

UEFI firmware for QEMU/KVM virtual machines.

Graphic card passthrough actually works with this firmware.

I am using prebuild binaries from [RPM package for example: edk2.git-ovmf-x64-0-20161216.b2373.g1f20b29.noarch.rpm](https://www.kraxel.org/repos/jenkins/edk2/), just extract it with your favorite archive manager.


### VirtIO Drivers

Windows are not supplied with performance friendly VirtIO drivers for hard drives and network drivers.

[Get it from here, search in page for "direct download", you need ISO file](https://fedoraproject.org/wiki/Windows_Virtio_Drivers)


## Script

    {% highlight bash %}
    #!/usr/bin/env bash

    # unbind the driver from the PCI device and bind it to the vfio
    #  you can find similar functions all over the internet
    vfiobind() {
        dev="$1"
        vendor=$(cat /sys/bus/pci/devices/$dev/vendor)
        device=$(cat /sys/bus/pci/devices/$dev/device)
        if [ -e /sys/bus/pci/devices/$dev/driver ]; then
            echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
        fi
        echo $vendor $device | tee /sys/bus/pci/drivers/vfio-pci/new_id
    }

    # to see exactly what the script is doing and
    #  terminate itself if command does not exit with 0
    set -xe

    vfiobind 0000:01:00.0  # graphic card
    vfiobind 0000:01:00.1  # graphic card audio
    # the same goes for any other PCI device like: audio (even if you use built in - motherboard audio) or USB controller

    qemu-kvm \
        -vga none \
        -m 10G \
        -cpu host,kvm=off \
        -smp 4,sockets=1,cores=4,threads=1 \
        -device vfio-pci,host=01:00.0,multifunction=on,x-vga=on \
        -device vfio-pci,host=01:00.1 \
        -drive if=pflash,format=raw,readonly,file=ovmf-x64/OVMF_CODE-pure-efi.fd \
        -drive if=pflash,format=raw,file=ovmf-x64/OVMF_VARS-pure-efi.fd \
        -usb -usbdevice host:05e3:0610 \
        -usbdevice host:1532:0202 \
        -usbdevice host:046d:c061 \
        -usbdevice host:046d:c21d \
        -usbdevice host:041e:30d3 \
        -netdev user,id=vmnic -device virtio-net,netdev=vmnic \
        -monitor stdio \
        -drive file=/dev/sdd,format=raw,cache=none,aio=native,if=virtio,index=1 \
        -drive file=./your_windows10_image.iso,media=cdrom,index=2 \
        -drive file=./virtio-win-0.1.126.iso,media=cdrom,index=3
    {% endhighlight %}


### Lets break down the qemu-kvm command

Set vga to none, you will be using graphic card's output and the second monitor,
so you do not need another window on host

    -vga none \


Pass 10GB from 16GB of RAM to the virtual machine and use host CPI and use all its 4 cores

    -m 10G \
    -cpu host,kvm=off \
    -smp 4,sockets=1,cores=4,threads=1 \


The actual passthrough of graphic card and its audio device (do the same for audio and/or USB controller if you are using PCI ones)

    -device vfio-pci,host=01:00.0,multifunction=on,x-vga=on \
    -device vfio-pci,host=01:00.1 \


Use OVMF (make a copy of original OVMF_VARS-pure-efi.fd before starting up the VM first time, when you play with different devices and things wont work as they should, just overwrite the OVMF_VARS-pure-efi.fd file with the original one)

    -drive if=pflash,format=raw,readonly,file=ovmf-x64/OVMF_CODE-pure-efi.fd \
    -drive if=pflash,format=raw,file=ovmf-x64/OVMF_VARS-pure-efi.fd \


Passing usb devices to the VM, I have all devices connected to VM through one USB hub and make sure that you passthrough USB hub the same way, the rest of devices I am passing are: mouse, keyboard, gamepad, usb audio

    -usb -usbdevice host:05e3:0610 \
    -usbdevice host:1532:0202 \
    -usbdevice host:046d:c061 \
    -usbdevice host:046d:c21d \
    -usbdevice host:041e:30d3 \


Network

    -netdev user,id=vmnic -device virtio-net,netdev=vmnic \


Have some control over virtual machine with qemu shell (windows like to sleep, so to wake it up, type in this console system_wakeup)

    -monitor stdio \


Pass the HDD/SSD directly and then iso images

    -drive file=/dev/sdd,format=raw,cache=none,aio=native,if=virtio,index=1 \
    -drive file=./your_windows10_image.iso,media=cdrom,index=2 \
    -drive file=./virtio-win-0.1.126.iso,media=cdrom,index=3


### Usage


First of all, save the script, make it executable and run as root (or with sudo), when in Windows installer at the point of choosing disk/partition - you will not see any of them, click on the button to load drivers and search for storage drivers inside the second cdrom device (virtio-win drivers), after successful import, choose disk and install Windows.

When you finally get to the OS inside virtual machine, you need to install network drivers, from virtio-win cdrom device.

Then install latest _official_ graphic card drivers.

After that, install Steam or GOG or whatever to download your favorite game and start playing.


#### Audio

If you are not using separate sound hardware, then you need to add special option to qemu-kvm command: _-soundhw ac97_ and then inside virtual machine download and install [this Realtek driver](http://www.realtek.com.tw/Downloads/downloadsCheck.aspx?Langid=1&PNid=14&PFid=23&Level=4&Conn=3&DownTypeID=3&GetDown=false) driver, more info on how to install is [here (click it, you will need it!)](http://stackoverflow.com/questions/32193050/qemu-pulseaudio-and-bad-quality-of-sound)

Do not forget to add root (or whatever user is running actual virtual machine) to pulse and/or audio groups:

    usermod -a -G pulse,audio root


Also, export following variables before running qemu-kvm command:

    export QEMU_AUDIO_DRV=alsa QEMU_AUDIO_TIMER_PERIOD=0 QEMU_PA_SAMPLES=128


### Issues


#### Audio

You might have audio issues - crackling sound, go to advanced settings for your playback device inside Windows and set DVD quality instead of already selected CD quality


#### CPU

It is tempting to use less cores instead of all, one reason for that could be, if something goes wrong within VM and if it goes in some sort of loop, it might consume all CPU power on host, but, don't, just don't, performance inside VM will suffer greatly, and even when I run Witcher 3, the host, using KDE, is responsive as before (as long as I do not run something CPU intensive on it ...).
