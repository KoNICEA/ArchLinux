#!/bin/bash

# --------------------
# |||| Functions |||||
# --------------------
function gen-arch-chroot {
echo "----------------------------------"
echo " -- Generate ArchChroot Script --"
echo "----------------------------------"
sleep 3

V1='$NUSR'
V2='$HSTN'
V3='$NBTL'
cat <<EOF > /mnt/root/complete.sh
    echo "----------------------------"
    echo " -- Install BasePackages --"
    echo "----------------------------"
    sleep 3
    pacman -S --needed --noconfirm grub efibootmgr sudo networkmanager base-devel

    echo "-----------------------------"
    echo " -- ArchLinux BaseConfigs --"
    echo "-----------------------------"
    sleep 3
    timedatectl set-timezone Europe/Rome
    ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
    hwclock --systohc
    mv /etc/locale.gen /etc/locale.gen.all
    echo it_IT.UTF-8 UTF-8 > /etc/locale.gen
    locale-gen
    echo LANG=it_IT.UTF-8 > /etc/locale.conf
    echo KEYMAP=it > /etc/vconsole.conf
    echo -n "HostName >> "
    read HSTN
    echo $V2 > /etc/hostname

    echo "--------------------------"
    echo " -- Configs /Etc/Hosts --"
    echo "--------------------------"
    sleep 1  
    echo >> /etc/host
    echo 127.0.0.1    localhost >> /etc/hosts
    echo ::1          localhost >> /etc/hosts
    echo >> /etc/hosts
    echo 127.0.0.1    $V2 >> /etc/hosts

    echo "-------------------------------"
    echo " -- Insert Password of Root --"
    echo "-------------------------------"
    passwd

    echo "----------------------"
    echo " -- Grub Configure --"
    echo "----------------------"
    sleep 2
    echo -n "Name Of BootLoader | UEFI- [E.G. CPH-LNX] >> "
    read NBTL
    grub-install --target=x86_64-efi --bootloader-id=UEFI-$V3 --efi-directory=/boot/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    mkinitcpio -P

    echo "----------------------------"
    echo " -- Create User and Home --"
    echo "----------------------------"
    sleep 1
    echo -n "UserName of New User >> "
    read NUSR
    useradd --create-home $V1
    passwd $V1
    usermod --append --groups wheel $V1
    echo "$V1    ALL=(ALL:ALL) ALL" >> /etc/sudoers

    echo "-----------------------"
    echo " -- Enable Services --"
    echo "-----------------------"
    sleep 2
    systemctl enable NetworkManager.service

    echo "---------------------------"
    echo " -- Complete.Sh in Home --"
    echo "---------------------------"
    echo "sudo pacman -Syu" 
    echo "sudo pacman -S --needed --noconfirm xorg-server nvidia nvidia-utils nvidia-settings xorg-xinit xorg-xrandr xorg-xsetroot" >> /home/$V1/complete.sh
    echo "sudo pacman -S --needed --noconfirm neofetch neovim unzip git htop dmenu feh chromium firefox xterm ntfs-3g" >> /home/$V1/complete.sh
    echo "sudo pacman -S --needed --noconfirm python python-pip ruby keepassxc mplayer mpd openssh openvpn" >> /home/$V1/complete.sh
    echo "sudo pacman -S --needed --noconfirm rp-pppoe wpa_supplicant wireless_tools networkmanager-strongswan nm-connection-editor" >> /home/$V1/complete.sh
    echo "sudo pacman -S --needed --noconfirm ttf-hanazono ttf-sazanami" >> /home/$V1/complete.sh
    echo "sudo pacman -S --needed --noconfirm libxcb xcb-util xcb-util-wm xcb-util-keysyms" >> /home/$V1/complete.sh

    echo "--------------------------------"
    echo " -- BspWM And Yay Complete.Sh --"
    echo "--------------------------------"    
    echo "git clone https://github.com/baskerville/bspwm.git && git clone https://github.com/baskerville/sxhkd.git && cd bspwm && make && sudo make install && cd ../sxhkd && make && sudo make install" >> /home/$V1/complete.sh
    echo "git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si" >> /home/$V1/complete.sh

    chmod +x /home/$V1/complete.sh
EOF

    sleep 1
    chmod +x /mnt/root/complete.sh
}

# ---------------
# |||| Main |||||
# ---------------
EFIVARS=/sys/firmware/efi/efivars
if [[ -d "$EFIVARS" ]]
then
    echo "-----------------------------"
    echo " -- Partition Disks --"
    echo "-----------------------------"
    sleep 3
    LSD=$(lsblk -o NAME,SIZE,MODEL)
    echo -e "\033[0;33m$LSD\033[0m"
    echo -n "Select Disk To Install Arch >> "
    read SDK
    dd if=/dev/zero of=/dev/$SDK bs=512 count=1
    echo -n "Size in GB of Root Partition >> "
    read SRP
    echo -n "Size in GB of Swap Partition >> "
    read SSP
    echo -e "g\nn\n\n\n+1G\nn\n\n\n+"$SRP"G\nn\n\n\n+"$SSP"G\nt\n1\n1\nt\n2\n20\nt\n3\n19\nw" | fdisk /dev/$SDK

    TRMS=""
    LCHR=${SDK: -1}
    REGX='^[0-9]+$'
    if [[ $LCHR =~ $REGX ]] ; then
       TRMS="p"
    fi

    mkfs.vfat -F32 "/dev/"$SDK$TRMS"1"
    mkfs.ext4 "/dev/"$SDK$TRMS"2"
    mkswap "/dev/"$SDK$TRMS"3"

    echo "-------------------------"
    echo " -- Install ArchLinux --"
    echo "-------------------------"
    sleep 3   
    mount "/dev/"$SDK$TRMS"2" /mnt
    pacstrap /mnt base linux linux-firmware
    mkdir /mnt/boot/efi
    mount "/dev/"$SDK$TRMS"1" /mnt/boot/efi
    swapon "/dev/"$SDK$TRMS"3"

    echo "----------------"
    echo " -- GenFstab --"
    echo "----------------"
    sleep 1
    genfstab -U /mnt >> /mnt/etc/fstab
    gen-arch-chroot
    arch-chroot /mnt /root/complete.sh

    echo "---------------------------------------------"
    echo " -- Completed! Now Reboot to Apply Modify --"
    echo "---------------------------------------------"
    read IEND

    rm /mnt/root/complete.sh
    exit

else
    echo "Reboot in UEFI..."
fi