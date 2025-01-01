#!/bin/bash

DISK=""
USER="solid"
mnt_opts="rw,noatime,compress-force=zstd:1,space_cache=v2"

timedatectl set-ntp true

wipefs -af $DISK
sgdisk --zap-all --clear $DISK
partprobe $DISK

sgdisk -n 0:0:+1G -t 0:ef00 -c 0:esp $DISK
sgdisk -n 0:0:0 -t 0:8309 -c 0:arch $DISK
sgdisk -p $DISK


mkfs.vfat -F32 -n ESP ${DISK}p1
mkfs.btrfs -L arch ${DISK}p2

mount ${DISK}p2 /mount

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@libvirt
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@tmp

umount /mnt

mount -o ${mnt_opts},subvol=@ ${DISK}p2 /mnt

mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}

mount -o ${mnt_opts},subvol=@home ${DISK}p2 /mnt/home
mount -o ${mnt_opts},subvol=@snapshots ${DISK}p2 /mnt/.snapshots
mount -o ${mnt_opts},subvol=@cache ${DISK}p2 /mnt/var/cache
mount -o ${mnt_opts},subvol=@tmp ${DISK}p2 /mnt/var/tmp
mount -o ${mnt_opts},subvol=@libvirt ${DISK}p2 /mnt/var/lib/libvirt
mount -o ${mnt_opts},subvol=@log ${DISK}p2 /mnt/var/log

mkdir /mnt/efi
mount ${DISK}p1 /mnt/efi

pacstrap /mnt base base-devel ${microcode} btrfs-progs amd-ucode linux-headers linux linux-firmware bash-completion htop man-db mlocate neovim networkmanager openssh pacman-contrib pkgfile sudo tmux git

genfstab -U -p /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash

ln -sf /usr/share/zoneinfo/America/Halifax /etc/localtime
hwclock --systohc

echo "bigboss" > /etc/hostname

cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
EOF

export locale="en_US.UTF-8"
sed -i "s/^#\(${locale}\)/\1/" /etc/locale.gen
echo "LANG=${locale}" > /etc/locale.conf
locale-gen

echo "EDITOR=nvim" > /etc/environment && echo "VISUAL=nvim" >> /etc/environment

echo "ENTER ROOT PASSWORD: "
PASSWORD

useradd -m -G wheel -s /bin/bash $USER
echo "ENTER USER PASS: "
passwd $USER

sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

systemctl enable networkmanager
systemctl enable paccache.timer
systemctl enable fstrim.timer

nvim /etc/mkinitcpio.conf

mkinitcpio -P 

pacman -S grub efibootmgr fuse3 ntfs-3g

nvim /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt/
reboot
