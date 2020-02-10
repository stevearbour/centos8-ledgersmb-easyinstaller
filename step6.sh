#!/bin/bash

WORKING_INSTALLATION_PATH="`dirname \"$0\"`"
WORKING_INSTALLATION_PATH="`( cd \"$WORKING_INSTALLATION_PATH\" && pwd )`"
. $WORKING_INSTALLATION_PATH/CONFIGURATION

clear
echo "*** PLEASE WAIT - INSTALLATION IN PROGRESS . . ."
echo " "
sleep $INSTALLER_SLEEP_ON_BOOT
echo "*** INSTALLER STEP 6 INITIATED"
echo " "

# LEDGERSMB PART 2
cd /usr/local/ledgersmb
sudo sed -i 's/^WorkingDirectory=.*/WorkingDirectory=\/usr\/local\/ledgersmb/g' /etc/systemd/system/ledgersmb_starman.service
sudo sed -i 's/^ExecStart=\/usr\/bin\/starman.*/ExecStart=\/usr\/local\/bin\/starman \\/g' /etc/systemd/system/ledgersmb_starman.service
useradd -d /non-existent -r -U -c "LedgerSMB/Starman service system user" ledgersmb

cd /usr/local/ledgersmb/UI/js-src/util/
npm install uglify-js@">=2.0 <3.0"

cd /usr/local/ledgersmb/
cpanm --quiet --notest --with-feature=starman --with-feature=latex-pdf-ps --with-feature=latex-pdf-images --installdeps /usr/local/ledgersmb/

cd /usr/local/ledgersmb/
make dojo

# END OF INSTALLATION
systemctl daemon-reload
systemctl enable postgresql
systemctl enable httpd
systemctl enable ledgersmb_starman
systemctl restart postgresql
systemctl restart httpd
systemctl restart ledgersmb_starman

# REMOVE /ETC/RC.LOCAL ENTRY 
sed -i '/step6.sh/d' /etc/rc.local

# REMOVE ENVIRONMENT CONFIGURATION
. REMOVE_CONFIGURATION

echo "Installation is (should be) complete"
echo " "
echo "Please open a compatible browser such as Mozilla Firefox, and point it to https://$LEDGERSMB_HOSTNAME/setup.pl to start using LedgerSMB"
echo " "
echo "This script was written by Steve Arbour"
echo " "

# END OF SCRIPT
