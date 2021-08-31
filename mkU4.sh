export Home=$HOME/Downloads

echo "Part 2"



sudo umount $Home/live-ubuntu-from-scratch/chroot/dev
sudo umount $Home/live-ubuntu-from-scratch/chroot/run

cd $Home/live-ubuntu-from-scratch
mkdir -p image/{casper,isolinux,install}
sudo cp chroot/boot/vmlinuz-**-**-generic image/casper/vmlinuz
sudo cp chroot/boot/initrd.img-**-**-generic image/casper/initrd
sudo cp chroot/boot/memtest86+.bin image/install/memtest86+

wget --progress=dot https://www.memtest86.com/downloads/memtest86-usb.zip -O image/install/memtest86-usb.zip
unzip -p image/install/memtest86-usb.zip memtest86-usb.img > image/install/memtest86
rm image/install/memtest86-usb.zip

cd $Home/live-ubuntu-from-scratch
touch image/ubuntu
echo"Create image/isolinux/grub.cfg"

cat <<EOF > image/isolinux/grub.cfg

search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=30

menuentry "Try Ubuntu FS without installing" {
   linux /casper/vmlinuz boot=casper quiet splash ---
   initrd /casper/initrd
}

menuentry "Install Ubuntu FS" {
   linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
   initrd /casper/initrd
}

menuentry "Check disc for defects" {
   linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
   initrd /casper/initrd
}

menuentry "Test memory Memtest86+ (BIOS)" {
   linux16 /install/memtest86+
}

menuentry "Test memory Memtest86 (UEFI, long load time)" {
   insmod part_gpt
   insmod search_fs_uuid
   insmod chain
   loopback loop /install/memtest86
   chainloader (loop,gpt1)/efi/boot/BOOTX64.efi
}
EOF

cd $Home/live-ubuntu-from-scratch
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest

sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop

sudo sed -i '/ubiquity/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/casper/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/discover/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/laptop-detect/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/os-prober/d' image/casper/filesystem.manifest-desktop

cd $Home/live-ubuntu-from-scratch

sudo mksquashfs chroot image/casper/filesystem.squashfs

printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

cd $Home/live-ubuntu-from-scratch

#Create file image/README.diskdefines
cat <<EOF > image/README.diskdefines
#define DISKNAME  Ubuntu from scratch
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
cd $Home/live-ubuntu-from-scratch/image

#Create a grub UEFI image
grub-mkstandalone \
   --format=x86_64-efi \
   --output=isolinux/bootx64.efi \
   --locales="" \
   --fonts="" \
   "boot/grub/grub.cfg=isolinux/grub.cfg"

#Create a FAT16 UEFI boot disk image containing the EFI bootloader
(
   cd isolinux && \
   dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
   sudo mkfs.vfat efiboot.img && \
   LC_CTYPE=C mmd -i efiboot.img efi efi/boot && \
   LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
)

#►Create a grub BIOS image
grub-mkstandalone \
   --format=i386-pc \
   --output=isolinux/core.img \
   --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
   --modules="linux16 linux normal iso9660 biosdisk search" \
   --locales="" \
   --fonts="" \
   "boot/grub/grub.cfg=isolinux/grub.cfg"

#►Combine a bootable grub cdboot.img
cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img
#►Generate md5sum.txt
sudo /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt)"

#Create iso from the image directory using the command-line
sudo xorriso \
   -as mkisofs \
   -iso-level 3 \
   -full-iso9660-filenames \
   -volid "Ubuntu from scratch" \
   -output "../ubuntu-from-scratch.iso" \
   -eltorito-boot boot/grub/bios.img \
      -no-emul-boot \
      -boot-load-size 4 \
      -boot-info-table \
      --eltorito-catalog boot/grub/boot.cat \
      --grub2-boot-info \
      --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
   -eltorito-alt-boot \
      -e EFI/efiboot.img \
      -no-emul-boot \
   -append_partition 2 0xef isolinux/efiboot.img \
   -m "isolinux/efiboot.img" \
   -m "isolinux/bios.img" \
   -graft-points \
      "/EFI/efiboot.img=isolinux/efiboot.img" \
      "/boot/grub/bios.img=isolinux/bios.img" \
      "."

sudo dd if=ubuntu-from-scratch.iso of=<device> status=progress oflag=sync
