#!/bin/bash

EFIVARS=/sys/firmware/efi/efivars
if [[ -d "$EFIVARS" ]]
then
    echo "-----------------------------"
    echo " -- Partition Disks --"
    echo "-----------------------------"    
    LSD=$(lsblk -o NAME,SIZE,MODEL)
    echo -e "\033[0;33m$LSD\033[0m"
    echo -n "Select Disk To Install Arch >> "
    read DISK
    echo -n "Select Disk >> "
    read SDK
    dd if=/dev/zero of=/dev/$SDK bs=512 count=1
    echo -n "Size in GB of Root Partition >> "
    read SRP
    echo -n "Size in GB of Swap Partition >> "
    read SSP
    echo -e "g\nn\n\n\n+1G\nn\n\n\n+"$SRP"G\nn\n\n\n+"$SSP"G\nt\n1\n1\nt\n2\n20\nt\n3\n19\nw" | fdisk /dev/$SDK
    mkfs.vfat -F32 "/dev/"$SDK"1"
    mkfs.ext4 "/dev/"$SDK"2"
    mkswap "/dev/"$SDK"3"

    echo "-------------------------"
    echo " -- Install ArchLinux --"
    echo "-------------------------"    
    mount "/dev/$SDK"2 /mnt
    pacstrap /mnt base linux linux-firmware	
    mkdir /mnt/boot/efi
    mount "/dev/$SDK"1 /mnt/boot/efi
    swapon "/dev/$SDK"3

    echo "----------------"
    echo " -- GenFstab --"
    echo "----------------"    
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt

    echo "----------------------------"
    echo " -- Install BasePackages --"
    echo "----------------------------"
    pacman -S grub efibootmgr ne

    echo "-----------------------------"
    echo " -- ArchLinux BaseConfigs --"
    echo "-----------------------------"
    timedatectl list-timezones
    timedatectl set-timezone Europe/Rome
    ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
    hwclock --systohc
    mv /etc/locale.gen /etc/locale.gen.all
    echo it_IT.UTF-8 UTF-8 > /etc.locale.gen
    locale-gen
    echo LANG=it_IT.UTF-8 > /etc/locale.conf
    echo KEYMAP=it > /etc/vconsole.conf
    echo DSK-CPH-EAP > /etc/hostname
    nano /etc/hosts

    echo "-------------------------------"
    echo " -- Insert Password of Root --"
    echo "-------------------------------"
    passwd
    grub-install --target=x86_64-efi --bootloader-id=UEFI-CPH-LNX --efi-directory=/boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    mkinitcpio -P

    echo "----------------------------"
    echo " -- Create User and Home --"
    echo "----------------------------"    
    useradd --create-home ciphered
    passwd ciphered
    usermod --append --groups wheel ciphered
    nano /etc/sudoers

    echo "---------------------------"
    echo " -- Complete.Sh in Home --"
    echo "---------------------------"  
    echo "pacman -Syu xorg-server nvidia nvidia-utils nvidia-settings xorg-xinit xorg-xrandr xorg-xsetroot neofetch neovim unzip git htop dmenu chromium firefox xterm ntfs-3g" >> /home/ciphered/complete.sh
    echo "pacman -S feh python python-pip ruby keepassxc mplayer mpd openssh openvpn" >> /home/ciphered/complete.sh
    echo "pacman -S networkmanager rp-pppoe wpa_supplicant wireless_tools networkmanager-strongswan nm-connection-editor" >> /home/ciphered/complete.sh
    echo "pacman -S sudo pacman -S ttf-hanazono ttf-sazanami" >> /home/ciphered/complete.sh
    echo "git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si" >> /home/ciphered/complete.sh
    chmod +x /home/ciphered/complete.sh
else
    echo "Reboot in UEFI..."
fi