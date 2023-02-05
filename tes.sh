#!/usr/bin/env bash

if (( $EUID != 0 )); then
    echo "Please run as root"
    echo "You can Try comand 'su root' or 'sudo -i'"
    exit 1
fi

sudo pkill -9 apt.systemd
echo "wait 10s"
sleep 10
sudo pkill -9 apt.systemd
lock1=/var/lib/apt/lists/lock
lock2=/var/lib/dpkg/lock-frontend
lock3=/var/lib/dpkg/lock
lock4=/var/cache/apt/archives/lock

for (( x=1; x<=4; x++ ))
do 
 plock="lock$x"
 if [ -f "${!plock}" ];then
     if [ -z $(lsof -t ${!plock}) ]
     then
        echo "Ok... file (${!plock}) already delete"
     else
        sudo kill -9 $(lsof -t ${!plock})
        echo "Found..PID (${!plock}) already kill & delete file"
     fi
 sudo rm ${!plock}
 fi
done

sudo dpkg --configure -a
sudo apt-get install --reinstall libappstream4 -y
sudo apt-get install -f
sudo apt-get update

sudo apt-get install openssh-server -y

if [ ! $(which jq) ]; then
    sudo apt-get install jq -y
fi

#for download manual https://dl.equinox.io/ngrok/ngrok-v3/stable/archive
# determine system arch
ARCH=
if [ "$(uname -m)" == 'x86_64' ]
then
    ARCH=amd64
elif [ "$(uname -m)" == 'aarch64' ]
then
    ARCH=arm64
elif [ "$(uname -m)" == 'i386' ] || [ "$(uname -m)" == 'i686' ]
then
    ARCH=386
else
    ARCH=arm
fi

ARCHIVE=ngrok-v3-stable-linux-$ARCH.tgz
DOWNLOAD_URL=https://bin.equinox.io/c/bNyj1mQVY4c/$ARCHIVE

mkdir -p /opt/dirngrok
cd /opt/dirngrok
if [ -f "/opt/dirngrok/ngrok.yml" ];then
    echo "OK…file 'ngrok.yml' Found"
else
    wget https://raw.githubusercontent.com/lamtota40/ngrok-easy-install/main/ngrok.yml --no-check-certificate
fi

if [ -f "/opt/dirngrok/ngrok.service" ];then
    echo "Ok… file 'ngrok.service' found and move to '/lib/systemd/system/'"
    sudo mv ngrok.service /lib/systemd/system/
else
    sudo wget https://raw.githubusercontent.com/lamtota40/ngrok-easy-install/main/ngrok.service --no-check-certificate -P /lib/systemd/system/  
fi

wget $DOWNLOAD_URL --no-check-certificate
tar xvf $ARCHIVE
rm $ARCHIVE
sudo chmod +x ngrok
cd

echo "Running ngrok v3 stable for ARCH $(uname -m) . . ."
systemctl enable ngrok.service
systemctl start ngrok.service

sudo apt install gparted -y
sudo apt install grml-rescueboot -y
sudo wget -P /boot/grml download.grml.org/grml64-full_2022.11.iso
#sudo apt-get install grub-imageboot -y
#sudo mkdir /boot/images
#sudo wget -P /boot/grml https://cdimage.debian.org/cdimage/archive/latest-oldstable/i386/iso-cd/debian-10.13.0-i386-netinst.iso
#sudo wget -O win7.iso https://ss2.softlay.com/files/en_windows_7_professional_x86_dvd.iso
#sudo mkdir /boot/customiso
#sudo wget -P /boot/customiso https://cdimage.debian.org/mirror/cdimage/archive/latest-oldstable-live/i386/iso-hybrid/debian-live-10.13.0-i386-lxde.iso
#sudo bash -c "echo 'CUSTOM_BOOTOPTIONS=\"ssh=pas123 vnc=pas123 dns=8.8.8.8,8.8.4.4 netscript=raw.githubusercontent.com/lamtota40/tes/main/setup-ngrok.sh startx toram\"' >> /etc/default/grml-rescueboot"
sudo bash -c "echo 'CUSTOM_BOOTOPTIONS=\"startx toram\"' >> /etc/default/grml-rescueboot"
echo -ne '\n' | sudo add-apt-repository ppa:danielrichter2007/grub-customizer
echo -ne '\n' | sudo apt update
sudo apt install grub-customizer -y

#sudo wget -N -P /etc/grub.d/ https://raw.githubusercontent.com/lamtota40/tes/main/40_custom
sudo update-grub

#echo -ne '\n' |sudo add-apt-repository ppa:nilarimogard/webupd8
#echo -ne '\n' |sudo apt-get update
#sudo apt-get install woeusb -y

STATUSNGROK=$(wget http://127.0.0.1:4040/api/tunnels -q -O - | jq '.tunnels | .[] | "\(.name) \(.public_url)"')
echo -e "service online NGROK:\n" $STATUSNGROK
#sudo grub-reboot 4
#sudo reboot
