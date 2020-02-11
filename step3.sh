#!/bin/bash

WORKING_INSTALLATION_PATH="`dirname \"$0\"`"
WORKING_INSTALLATION_PATH="`( cd \"$WORKING_INSTALLATION_PATH\" && pwd )`"
. $WORKING_INSTALLATION_PATH/CONFIGURATION

clear
echo " "
echo "-> INSTALLER STEP 3 INITIATED : PACKAGES AND NET/DB/LEDGERSMB SERVICE INSTALLATION PART 1"
echo " "
sleep 3


# FIRST ROUND OF PACKAGES INSTALLATION
dnf -y install nano gcc make wget git net-tools cpan cpanminus perl epel-release
dnf -y install httpd 
dnf -y install postgresql postgresql-devel postgresql-server
dnf -y install perl-CGI-Emulate-PSGI perl-CGI-Simple perl-Config-IniFiles
dnf -y install perl-DBD-Pg perl-DBI perl-DateTime perl-DateTime-Format-Strptime
dnf -y install perl-Digest-MD5 perl-File-MimeInfo perl-JSON-XS
dnf -y install perl-Locale-Maketext perl-Locale-Maketext-Lexicon
dnf -y install perl-Log-Log4perl perl-MIME-Base64 perl-MIME-Lite perl-Math-BigInt-GMP
dnf -y install perl-Moose perl-Number-Format perl-Plack perl-Template-Toolkit
dnf -y install perl-namespace-autoclean perl-MooseX-NonMoose perl-XML-Simple
dnf -y install perl-TeX-Encode texlive
dnf -y install libpqxx libpqxx-devel
dnf -y install perl-JSON-MaybeXS
dnf -y install perl-Starman
dnf -y install perl-CGI-Emulate-PSGI perl-CGI-Simple perl-Config-IniFiles perl-DBD-Pg perl-DBI perl-DateTime perl-DateTime-Format-Strptime perl-Digest-MD5 perl-File-MimeInfo perl-JSON-XS perl-Locale-Maketext perl-Locale-Maketext-Lexicon perl-Log-Log4perl perl-MIME-Base64 perl-MIME-Lite perl-Math-BigInt-GMP perl-Moose perl-Number-Format perl-Plack perl-Template-Toolkit perl-namespace-autoclean perl-MooseX-NonMoose perl-XML-Simple
dnf -y install expat-devel
dnf -y install texlive-latex
dnf -y install redhat-lsb
dnf -y install nodejs nodejs-devel nodejs-packaging nodejs-docs
dnf -y install java-latest-openjdk

# CONFIGURING FIREWALL
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
systemctl restart firewalld

# ACTIVATE HTTPD
systemctl enable httpd
systemctl start httpd

# POSTGRESQL
systemctl enable postgresql
postgresql-setup --initdb --unit postgresql
systemctl start postgresql
eval "su - postgres -c 'yes "$LEDGERSMB_LSMB_DBADMIN_PASS" | createuser -S -d -r -l -P lsmb_dbadmin'"

cat >/var/lib/pgsql/data/pg_hba.conf <<EOL
local   all             postgres                         peer
local   all             all                              peer
host    all             postgres         127.0.0.1/32     reject
host    all             postgres        ::1/128      reject
host    postgres,template0,template1   lsmb_dbadmin         127.0.0.1/32     md5
host    postgres,template0,template1   lsmb_dbadmin         ::1/128      md5
host    postgres,template0,template1   all          127.0.0.1/32     reject
host    postgres,template0,template1   all          ::1/128      reject
host    all             all             127.0.0.1/32     md5
host    all             all             ::1/128          md5
EOL

systemctl restart postgresql

# LEDGERSMB PART 1
cd /usr/local
git clone --recurse https://github.com/ledgersmb/LedgerSMB /usr/local/ledgersmb
chown -R apache:apache /usr/local/ledgersmb/UI
cp /usr/local/ledgersmb/doc/conf/ledgersmb.conf.default /usr/local/ledgersmb/ledgersmb.conf
cp /usr/local/ledgersmb/doc/conf/systemd/ledgersmb_starman.service /etc/systemd/system/


$WORKING_INSTALLATION_PATH/step4.sh

# END OF SCRIPT - STEP 3

