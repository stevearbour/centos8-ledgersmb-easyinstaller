#!/bin/bash

clear
echo "**************************************************************************************************"
echo " CentOS 8 - LedgerSMB - Easy Installer "
echo "**************************************************************************************************"
echo " "
echo "Installation script written by Steve Arbour"
echo "Please report any problem so that I try to improve this installation script."
echo " "
echo "Tested with latest version of CentOS 8 (4.18.0-147.5.1.el8_1.x86_64)"
echo "Installation will start in 10 seconds... "
echo " "
echo "**************************************************************************************************"
echo "WARNING : Please do not touch or operate the system during the installation, "
echo "it should reboot at the end and be ready to access setup.pl "
echo "**************************************************************************************************"
echo " "
sleep 10

WORKING_INSTALLATION_PATH="`dirname \"$0\"`"
WORKING_INSTALLATION_PATH="`( cd \"$WORKING_INSTALLATION_PATH\" && pwd )`"
. $WORKING_INSTALLATION_PATH/CONFIGURATION

if [ $# > 0 ] && [ $# -eq 2 ]
then
	if [ $1 == 'enforcing' ] || [ $1 == 'disabled' ] || [ $1 == 'permissive' ]
	then
		export LEDGERSMB_SELINUX_MODE=$1
	fi
	if [ $2 == 'enabled' ] || [ $2 == 'disabled' ]
	then
		export LEDGERSMB_IPV6=$2
	fi
elif [ $# -eq 0 ]
then
    export LEDGERSMB_SELINUX_MODE=enforcing
    export LEDGERSMB_IPV6=disabled
else
	echo "CentOS 8 - LedgerSMB - Easy Installer "
	echo " "
	echo "Usage: install.sh <selinux_mode> <ipv6_mode>"
	echo " "
	echo "Valid values for <selinux_mode> enforcing, permissive, disabled"
	echo "Default is: enforcing "
	echo " "
	echo "Valid values for <ipv6_mode> enabled, disabled"
	echo "Default is: disabled"
	echo " "
	echo " "
	echo "Ex: './install.sh' would default install with selinux enforcing configured and ipv6 disabled."
	echo "Ex: './install.sh disabled enabled' would install with selinux disabled and ipv6 enabled."
	exit 2
fi	
		


chmod ug+x $WORKING_INSTALLATION_PATH/step2.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step3.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step4.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step5.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step6.sh

# DISABLE SELINUX IF NECESSARY
if [ $LEDGERSMB_SELINUX_MODE == 'disabled' ]
then 
	echo "SETTING SELINUX TO DISABLED..."
	sleep 2
	echo 0 > /selinux/enforce
	setenforce 0
	sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
elif [ $LEDGERSMB_SELINUX_MODE == 'permissive' ]
then 
	echo "SETTING SELINUX TO PERMISSIVE..."
	sleep 2
	echo 0 > /selinux/enforce
	setenforce 0
	sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
else
	echo "CONFIGURING SELINUX TO ALLOW LEDGERSMB..."
	sleep 2
	semanage port -a -t http_port_t -p tcp 5762
	setsebool -P httpd_can_network_connect 1
fi

# MODIFYING GRUB TO DISABLE IPV6 IF NECESSARY
if [ $LEDGERSMB_IPV6 == 'disabled' ]
then 
	echo "DISABLING IPv6..."
	sysctl -w net.ipv6.conf.all.disable_ipv6=1
	printf "\nGRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX ipv6.disable=1\"" >> /etc/default/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
	grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
fi

cat >/etc/systemd/system/rc-local.service <<EOL
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes

[Install]
 WantedBy=multi-user.target
EOL

# PREPARING NEXT BOOT
chmod +x /etc/rc.local
systemctl enable rc-local
systemctl status rc-local

$WORKING_INSTALLATION_PATH/step2.sh

# END OF SCRIPT - STEP 1

