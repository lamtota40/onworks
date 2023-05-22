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
sudo apt-get install jq wget curl -y

#remove firewall
sudo ufw disable
apt purge ufw -y

Login="master"
Pass="admin"
useradd -m -s /bin/bash $Login
echo -e "$Pass\n$Pass\n" | passwd $Login &> /dev/null
usermod -aG sudo $Login

apt install openssh-server -y
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication .*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication .*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords .*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
service sshd restart

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

systemctl enable ngrok.service
systemctl start ngrok.service

sudo apt install grml-rescueboot -y
sudo wget -O /boot/grml download.grml.org/grml64-full_2022.11.iso -O grml.iso
sudo bash -c "echo 'CUSTOM_BOOTOPTIONS=\"ssh=pas123 vnc=pas123 dns=8.8.8.8,8.8.4.4 netscript=raw.githubusercontent.com/lamtota40/tes/main/setup-ngrok.sh startx toram\"' >> /etc/default/grml-rescueboot"
echo -ne '\n' | sudo add-apt-repository ppa:danielrichter2007/grub-customizer
echo -ne '\n' | sudo apt update
sudo apt install grub-customizer -y
wget -O /boot/grml/ubuntu20.iso https://releases.ubuntu.com/focal/ubuntu-20.04.6-live-server-amd64.iso
sudo update-grub

STATUSNGROK=$(wget http://127.0.0.1:4040/api/tunnels -q -O - | jq '.tunnels | .[] | "\(.name) \(.public_url)"')
echo -e "service online NGROK:\n" $STATUSNGROK
cd
read -p "to continue Reboot please [ENTER]"
#grup-reboot
