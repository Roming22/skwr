#!/bin/bash
SCRIPT_DIR=`cd $(dirname $0); pwd`

if [[ "$UID" != "0" ]];then
	echo "Script must be run as root"
	exit 1
fi
set -e


update_system(){
	pacman-key --init
	pacman-key --populate archlinuxarm
	pacman -Syyu
}


install_packages(){
	for PACKAGE in docker git podman rsync sudo vim; do
		echo "Installing $PACKAGE..."
		pacman -S --noconfirm $PACKAGE
		case $PACKAGE in
			docker)
				systemctl start docker
				systemctl enable docker
				egrep -q "^docker:" /etc/group || groupadd docker
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


setup_users(){
	# Setup pi user
	if [[ ! -e "/home/pi" ]]; then
		echo "Creating user pi ..."
		useradd -m pi
		usermod -aG docker pi
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
	# Change the hostname
	hostnamectl set-hostname rpi

	GATEWAY=`ip route | grep default | awk '{print $3}'`

	IP=`ifconfig eth0 | grep " inet " | awk '{print $2}'`
	PREFIX=`echo $IP | cut -d. -f1-3`
	for SUFFIX in `seq 1 254`; do
		NEW_IP="$PREFIX.$SUFFIX"
		ping -c 1 $NEW_IP || break
	done

	echo "[Match]
Name=eth0

[Network]
Address=$NEW_IP/24
Gateway=$GATEWAY
DNS=$GATEWAY" > /etc/systemd/network/eth0.network
}

__rsync(){
	SOURCE="$SCRIPT_DIR/system$1"
	TARGET="$1"

	[[ -d "$SOURCE" ]] && SOURCE="$SOURCE/" && mkdir -p "$TARGET"
	rsync --archive --no-o --no-g "$SOURCE" "$TARGET"
}

update_system
install_packages
setup_users
setup_network
