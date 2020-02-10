#!/bin/bash

echo "Welcome to the LedgerSMB Easy Installer for CentOS 8"
echo " "
echo "Installation script written by Steve Arbour"
echo " "
echo "Please report any problem so that I try to improve this installation script."
echo " "
echo "Tested with latest version of CentOS 8 (4.18.0-147.5.1.el8_1.x86_64)"
echo " "
echo "Installation will start in 15 seconds... "
echo " "
echo "**********************************************"
echo "WARNING : Please do not touch or operate the system during the installation, "
echo "it should reboot up to 5 times and may appear hanging out at boot because of "
echo "a pause that I introduce at each boot sequence with sleep timer setting."
echo "INSTALLER_SLEEP_ON_BOOT=15 (Default 15 seconds)"
echo "**********************************************"
echo " "
sleep 15

WORKING_INSTALLATION_PATH="`dirname \"$0\"`"
WORKING_INSTALLATION_PATH="`( cd \"$WORKING_INSTALLATION_PATH\" && pwd )`"
. $WORKING_INSTALLATION_PATH/CONFIGURATION

chmod ug+x $WORKING_INSTALLATION_PATH/step2.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step3.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step4.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step5.sh
chmod ug+x $WORKING_INSTALLATION_PATH/step6.sh

# DISABLE SELINUX
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

# MODIFYING GRUB TO DISABLE IPV6
printf "\nGRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX ipv6.disable=1\"" >> /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

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
#systemctl start rc-local

cat >>/etc/rc.local <<EOL
$WORKING_INSTALLATION_PATH/step2.sh
EOL


# REMOVE ENVIRONMENT CONFIGURATION
. $WORKING_INSTALLATION_PATH/REMOVE_CONFIGURATION

reboot

# END OF SCRIPT

