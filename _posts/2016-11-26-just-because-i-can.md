---
layout: post
title: Just Because I Can
tags:
- linux
comments: true
---

Installing Debian _manually_ to external SSD on A20-OLinuXino-LIME2-eMMC board.


Intro
-----

#### Debian

If you do not know what is this, then stop reading.


#### A20-OLinuXino-LIME2-eMMC

Its an ARM board details on the [Wiki](https://www.olimex.com/wiki/A20-OLinuXino-LIME2)


Why?!
-----

If you havent read the title of this post... now it's time that you do so.


Make bootable microSD card
--------------------------

Example:

{% highlight bash %}
dd if=a20-lime2_mainline_uboot_sunxi_kernel_3.4.103_jessie_emmc_rel_9.img of=/dev/mmcblkX
{% endhighlight %}


SATA disk cables
----------------

For this to work you will need SATA data cable (if you are a real geek, like me,
than you have that lying around somewhere) and the SATA power cable, you can
order those things right [here](https://www.olimex.com/Products/Components/Cables/SATA-CABLE-SET/).

Power cable can be made right at home, I used one [molex(male) to SATA](https://www.amazon.com/s?ie=UTF8&page=1&rh=i%3Aaps%2Ck%3Amolex%20to%20sata)
(I had that from old motherboard or PSU), and then I made (soldered) a USB(male, A-type) to MOLLEX(female):

MOLLEX has 4 pins:

    - yellow is 15V
    - middle black two are ground
    - red is 5V

I used only the red one and the neighboring black one

USB has also 4 pins:

    - red is 5V
    - white and green data
    - black is ground

I soldered red to red and the selected black to black

Note #1: if you havent got all the right colors on the either of Mollex or USB,
check and recheck Google, if not done wright you might kill your HDD/SSD or
even Lime2 board.

Note #2: you can also solder the male molex directly to the USB (mind the
colors!!), I just wanted to preserve my precious molex-to-sata power cable.

Now you just need a 5V USB/phone charger to connect to your usb-to-molex cable and it
to the molex-to-sata power cable and then it to the Lime2.


Commands
--------

Insert microSD made previously and plug in the power cable to start the board booting.

Run theese commands on board as root:

With _fdisk_ create new DOS partition table and create 3 partitions (boot, swap and root)

{% highlight bash %}
fdisk /dev/sda
{% endhighlight %}


Format the partitions

{% highlight bash %}
mkfs.vfat /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3
{% endhighlight %}


Copy over the relevant data

{% highlight bash %}
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
cp -av /boot/* /mnt/boot/
mkdir /mnt/root
mount /dev/sda3 /mnt/root
find / -mindepth 1 -maxdepth 1 \( -not -name boot -not -name mnt -not -name proc -not -name run -not -name dev -not -name sys \) -exec cp -av "{}" "/mnt/root""{}" \;
{% endhighlight %}


Replace/add the some relavant things...

{% highlight bash %}
sed -i 's/mmcblk0p2/sda3/g' /mnt/boot/uEnv.txt
sed -i 's/mmcblk0p1/sda1/g' /mnt/sda3/etc/fstab
echo '/dev/sda2 none swap defaults 0 0' >> /mnt/sda3/etc/fstab
{% endhighlight %}


Edit: /mnt/boot/boot.cmd

    - from official image I changed the _root=_ for the _bootargs_
    - added _scsi scan_ (I found this somewhere on the internet)
    - changed _mmc_ occurrences to _scsi_

Result:

```
setenv bootm_boot_mode sec
setenv bootargs console=ttyS0,115200 root=/dev/sda3 rootwait panic=10
scsi scan
load scsi 0:1 0x43000000 script.bin || load scsi 0:1 0x43000000 boot/script.bin
load scsi 0:1 0x42000000 uImage || load scsi 0:1 0x42000000 boot/uImage
setenv machid 10bb
bootm 0x42000000
```

Convert the _boot.cmd_ to _boot.scr_

{% highlight bash %}
apt-get install u-boot-tools
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n 'Execute boot commands' -d /mnt/boot/boot.cmd /mnt/boot/boot.scr
{% endhighlight %}


Restart and press any key at u-boot boot time to stop at u-boot shell, and run:

{% highlight bash %}
run bootcmd_scsi0
{% endhighlight %}

Watch for the errors... or it will boot into the system on /dev/sda3
(sda - your hard drive; 3 - third, root partition)

If you are happy with it you can copy the _/boot/boot.scr_ from the _/dev/sda1_ partition to the same place at _/dev/mmcblk0p1_ partition, and it will automagicaly boot into the system on hard drive.

At this point there are few notes: the /dev/sda1 is unused and you do need
/dev/mmcblk0p1 as boot partition, I have no idea yet how to use the /dev/sda1
as boot or even internal /dev/mmcblk1p1 for the boot partition,
but for now it does not bother me to have extra mmc card in the slot.


Links
-----

[Wiki page for A20-OLinuXino-LIME2, which I havent read.. yet](https://www.olimex.com/wiki/A20-OLinuXino-LIME2)

[Official torrent to the Debian Jessie Image for LIME2-eMMC](https://www.olimex.com/wiki/images/2/20/A20-lime2_mainline_uboot_sunxi_kernel_3.4.103_jessie_emmc_rel_9.torrent)
