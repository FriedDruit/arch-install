#!/bin/bash

sudo nvim /etc/pacman.conf
sudo pacman updatedb
sudo pkgfile --update 

sudo pacman -S pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils

cd
mkdir opt
cd opt

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay -S zramd
sudo systemctl enable --now zramd.service

sudo pacman -S snapper

sudo umount /.snapshots 
sudo rm -rf /.snapshots 
sudo snapper -c root create-config / 
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots 
sudo mount -a
sudo chmod 750 /.snapshots
sudo chown :wheel /.snapshots
sudo snapper -c root create -d "**BASE**"

sudo nvim /etc/snapper/configs/root
sudo nvim /etc/updatedb.conf 

sudo pacman -S firefox vlc kitty xorg bspwm polybar feh rofi sxhkd xorg-xinit xorg-xrandr brightnessctl ttf-fontawesome
sudo pacman -S nvidia-open-dkms nvidia-settings nvidia-utils lib32-nvidia-utils cuda opencl-headers opencl-nvidia

sudo nvim /etc/mkinitcpio.conf 
sudo mkinitcpio -P 

sudo echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf
  
yay -S nerd-fonts 
pacman -S blender godot steam

