#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.net/rootfs/"
DIR="$PWD"

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

./RootStock-NG.sh -c rcn-ee_console_debian_stable_armhf
./RootStock-NG.sh -c rcn-ee_console_debian_testing_armhf
./RootStock-NG.sh -c rcn-ee_console_ubuntu_stable_armhf

debian_stable="debian-7.8-console-armhf-${time}"
debian_testing="debian-jessie-console-armhf-${time}"
ubuntu_stable="ubuntu-14.04.2-console-armhf-${time}"

archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

copy_base_rootfs_to_mirror () {
        if [ -d ${mirror_dir} ] ; then
                if [ ! -d ${mirror_dir}/${time}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/ ] ; then
                        if [ -f \${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar.xz ${mirror_dir}/${time}/
                        fi
                fi
        fi
}

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ ! -f \${base_rootfs}.tar.xz ] ; then
                ${archive} \${base_rootfs}.tar
        fi
        copy_base_rootfs_to_mirror
}

extract_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ -f \${base_rootfs}.tar.xz ] ; then
                tar xf \${base_rootfs}.tar.xz
        else
                tar xf \${base_rootfs}.tar
        fi
}

copy_img_to_mirror () {
        if [ -d ${mirror_dir} ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ -f \${wfile}.xz ] ; then
                                cp -v \${wfile}.xz ${mirror_dir}/${time}/\${blend}/
                        fi
                fi
        fi
}

archive_img () {
        if [ -f \${wfile} ] ; then
                ${archive} \${wfile}
                copy_img_to_mirror
        fi
}

generate_img () {
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        cd ..
}

#Debian Stable
base_rootfs="${debian_stable}" ; extract_base_rootfs

options="--img BBB-eMMC-flasher-${debian_stable} --dtb beaglebone --bbb-flasher --enable-systemd  --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bone-${debian_stable} --dtb beaglebone --enable-systemd --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bb-${debian_stable} --dtb omap3-beagle --enable-systemd" ; generate_img
options="--img bbxm-${debian_stable} --dtb omap3-beagle-xm --enable-systemd" ; generate_img
options="--img omap5-uevm-${debian_stable} --dtb omap5-uevm --enable-systemd" ; generate_img
options="--img bbx15-${debian_stable} --dtb am57xx-beagle-x15 --enable-systemd" ; generate_img

#Ubuntu Stable
base_rootfs="${ubuntu_stable}" ; extract_base_rootfs

options="--img BBB-eMMC-flasher-${ubuntu_stable} --dtb beaglebone --bbb-flasher  --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bone-${ubuntu_stable} --dtb beaglebone --bbb-old-bootloader-in-emmc" ; generate_img
options="--img bb-${ubuntu_stable} --dtb omap3-beagle" ; generate_img
options="--img bbxm-${ubuntu_stable} --dtb omap3-beagle-xm" ; generate_img
options="--img omap5-uevm-${ubuntu_stable} --dtb omap5-uevm" ; generate_img
options="--img bbx15-${ubuntu_stable} --dtb am57xx-beagle-x15" ; generate_img

#Archive tar:
base_rootfs="${debian_stable}" ; archive_base_rootfs
base_rootfs="${ubuntu_stable}" ; archive_base_rootfs
base_rootfs="${debian_testing}" ; archive_base_rootfs

#Archive img:
blend="microsd"
wfile="bone-${debian_stable}-2gb.img" ; archive_img
wfile="bb-${debian_stable}-2gb.img" ; archive_img
wfile="bbxm-${debian_stable}-2gb.img" ; archive_img
wfile="omap5-uevm-${debian_stable}-2gb.img" ; archive_img
wfile="bbx15-${debian_stable}-2gb.img" ; archive_img

wfile="bone-${ubuntu_stable}-2gb.img" ; archive_img
wfile="bb-${ubuntu_stable}-2gb.img" ; archive_img
wfile="bbxm-${ubuntu_stable}-2gb.img" ; archive_img
wfile="omap5-uevm-${ubuntu_stable}-2gb.img" ; archive_img
wfile="bbx15-${ubuntu_stable}-2gb.img" ; archive_img

blend="flasher"
wfile="BBB-eMMC-flasher-${debian_stable}-2gb.img" ; archive_img
wfile="BBB-eMMC-flasher-${ubuntu_stable}-2gb.img" ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

if [ ! -d /mnt/farm/images/ ] ; then
	#nfs mount...
	sudo mount -a
fi

if [ -d /mnt/farm/images/ ] ; then
	cp -v ${DIR}/deploy/*.tar /mnt/farm/images/
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/gift_wrap_final_images.sh
	chmod +x /mnt/farm/images/gift_wrap_final_images.sh
fi

