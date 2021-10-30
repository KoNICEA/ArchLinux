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
cat <<EOF > /mnt/root/complete.sh
    echo "----------------------------"
    echo " -- Install BasePackages --"
    echo "----------------------------"
    sleep 3
    pacman -S --needed grub efibootmgr sudo

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
    grub-install --target=x86_64-efi --bootloader-id=UEFI-CPH-LNX --efi-directory=/boot/efi
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
    nano /etc/sudoers

    echo "---------------------------"
    echo " -- Complete.Sh in Home --"
    echo "---------------------------"  
    echo "pacman -Syu --needed xorg-server nvidia nvidia-utils nvidia-settings xorg-xinit xorg-xrandr xorg-xsetroot neofetch neovim unzip git htop dmenu chromium firefox xterm ntfs-3g " >> /home/$V1/complete.sh
    echo "pacman -S " >> /home/$V1/complete.sh
    echo "pacman -S networkmanager rp-pppoe wpa_supplicant wireless_tools networkmanager-strongswan nm-connection-editor" >> /home/$V1/complete.sh
    echo "pacman -S sudo pacman -S ttf-hanazono ttf-sazanami" >> /home/$V1/complete.sh
    echo "git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si" >> /home/$V1/complete.sh
    chmod +x /home/$V1/complete.sh
EOF
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
    mkfs.vfat -F32 "/dev/"$SDK"1"
    mkfs.ext4 "/dev/"$SDK"2"
    mkswap "/dev/"$SDK"3"

    echo "-------------------------"
    echo " -- Install ArchLinux --"
    echo "-------------------------"
    sleep 3   
    mount "/dev/$SDK"2 /mnt
    pacstrap /mnt base linux linux-firmware	
    mkdir /mnt/boot/efi
    mount "/dev/$SDK"1 /mnt/boot/efi
    swapon "/dev/$SDK"3

    echo "----------------"
    echo " -- GenFstab --"
    echo "----------------"
    sleep 1
    genfstab -U /mnt >> /mnt/etc/fstab
    gen-arch-chroot
    arch-chroot /mnt /root/complete.sh

else
    echo "Reboot in UEFI..."
fi