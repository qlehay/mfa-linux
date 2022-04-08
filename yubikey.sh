#!/bin/bash

GDM_LINE=`grep -n common-session /etc/pam.d/gdm-password|awk -F ':' '{ print $1}'`
LOGIN_LINE=`grep -n common-account /etc/pam.d/login|awk -F ':' '{ print $1}'`
SUDO_LINE=`grep -n common-account /etc/pam.d/sudo|awk -F ':' '{ print $1}'`

GDM_AUTH_LINE=`grep -n pam_u2f /etc/pam.d/gdm-password`
LOGIN_AUTH_LINE=`grep -n pam_u2f /etc/pam.d/login`
SUDO_AUTH_LINE=`grep -n pam_u2f /etc/pam.d/sudo`

U2F_FILE=/etc/Yubico/u2f_keys

sudo add-apt-repository ppa:yubico/stable -y && sudo apt-get update


sudo apt install libpam-u2f yubikey-manager -y

if [ ! -f "$U2F_FILE" ]; then
	mkdir -p ~/.config/Yubico

	echo "Appuyer sur la Yubikey lorsqu'elle se met à flasher"
	pamu2fcfg > ~/.config/Yubico/u2f_keys

	sudo mkdir -p /etc/Yubico/
	sudo mv ~/.config/Yubico/u2f_keys /etc/Yubico/
fi


echo "Configue Gnome Desktop Manager Authentication"
if [ -z "$GDM_AUTH_LINE" ]; then
	if [ -n "$GDM_LINE" ]; then
		echo "Adding Line at $GDM_LINE"
		sudo sed -i "${GDM_LINE}i auth required pam_u2f.so authfile=/etc/Yubico/u2f_keys cue" /etc/pam.d/gdm-password
	fi		
fi

echo "Configue TTY Authentication"
if [ -z "$LOGIN_AUTH_LINE" ]; then
	if [ -n "$LOGIN_LINE" ]; then
		echo "Adding Line at $LOGIN_LINE"
		sudo sed -i "${LOGIN_LINE}i auth required pam_u2f.so authfile=/etc/Yubico/u2f_keys cue" /etc/pam.d/login
	fi		
fi

echo "Configue Gnome Desktop Manager Authentication"
if [ -z "$SUDO_AUTH_LINE" ]; then
	if [ -n "$SUDO_LINE" ]; then
		echo "Adding Line at $SUDO_LINE"
		sudo sed -i "${SUDO_LINE}i auth required pam_u2f.so authfile=/etc/Yubico/u2f_keys cue" /etc/pam.d/sudo
	fi		
fi

echo 'SUBSYSTEMS=="usb", ACTION=="remove", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", RUN+="/bin/loginctl lock-sessions"'|sudo tee /etc/udev/rules.d/00-yubikey-lock.rules

sudo udevadm control --reload
