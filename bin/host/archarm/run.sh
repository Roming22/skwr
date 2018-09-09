#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

if [[ "$UID" != "0" ]];then
	echo "Script must be run as root"
	exit 1
fi
set -e

# Install packages
install_packages(){
	pacman-key --init
	pacman-key --populate archlinuxarm
	for PACKAGE in docker git rsync sudo vim; do
		echo "Installing $PACKAGE..."
		pacman -Syu --noconfirm $PACKAGE
		case $PACKAGE in
			docker)
				cat /etc/group | egrep -q "^docker:" || groupadd docker
				usermod -aG docker pi
				systemctl enable docker
				systemctl start docker
				;;
			sudo)
				__rsync /etc/sudoers.d
				;;
			vim)
				__rsync /etc/vimrc
				;;
		esac
	done
}


# Setup users
setup_users(){
	# Setup pi user
	if [[ ! -e "/home/pi" ]]; then
		echo "Creating user pi ..."
		useradd -m pi
		echo "pi:pi" | chpasswd
		__rsync /home/pi
		chown -R pi:pi /home/pi
	fi

	# Remove default user
	if [[ -e "/home/alarm" ]]; then
		echo "Removing default user alarm ..."
		userdel -r alarm
	fi

	# Disable root user
	passwd -l root
	echo "User root disabled"
}

# Deploy network configuration
setup_network(){
	hostnamectl set-hostname rpi

	# Setup interfaces
	rm -f /etc/systemd/network/*.network /etc/systemd/network/*.link
	__rsync /etc/systemd/network
	__rsync /etc/netctl
	WLAN_MAC=`cat /sys/class/net/wlan0/address`
	SOC_MAC=`cat /sys/class/net/*/address | grep $(echo $WLAN_MAC | cut -d: -f1-3) | grep -v $WLAN_MAC`
	SOC_NAME=`grep $SOC_MAC /sys/class/net/*/address | cut -d: -f1 | cut -d/ -f5`
	USB_MAC=`cat /sys/class/net/$(ls /sys/class/net/ | egrep -v "^lo$|^$SOC_NAME$|^wlan0$|^docker0$|^br-|^veth")/address`
	sed -i -e "s|MACAddress=.*|MACAddress=$SOC_MAC|" /etc/systemd/network/10-ethsoc.link
	sed -i -e "s|MACAddress=.*|MACAddress=$USB_MAC|" /etc/systemd/network/10-ethusb0.link

	# Restart network if necessary
	NEW_IP=`egrep "^Address" /etc/netctl/lan0-profile | cut -d"'" -f2 | cut -d/ -f1`
	if [[ `ifconfig eth0 | grep 'inet ' | awk '{print $2}'` != $NEW_IP ]]; then
		echo "Network interface is being restarted. Use $NEW_IP to connect to the server."
	fi
	for interface in `egrep '^Name=' /etc/systemd/network/*.network | cut -d= -f2`; do
		netctl enable ${interface}-profile
	done
}

__rsync(){
	SOURCE="$SCRIPT_DIR/system$1"
	TARGET="$1"

	[[ -d "$SOURCE" ]] && SOURCE="$SOURCE/" && mkdir -p "$TARGET"
	rsync --archive --no-o --no-g "$SOURCE" "$TARGET"
}

install_packages
setup_users
setup_network
