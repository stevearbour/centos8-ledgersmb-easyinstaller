#!/bin/bash

function display_help() {
    echo " "
    echo "######################################################################################"
    echo "# CentOS 8 - LedgerSMB - Easy Installer "
    echo "######################################################################################"
    echo "# "
    echo "# Usage: install.sh <selinux_mode> <ipv6_mode> <ledgersmb_git_branch>"
    echo "# "
    echo "# Valid values for <selinux_mode> enforcing, permissive, disabled (Default is: enforcing)"
    echo "# Valid values for <ipv6_mode> enabled, disabled (Default is: disabled)"
    echo "# Valid values for <ledgersmb_git_branch> 1.7, master (Default is: master)"
    echo "# "
    echo "# "
    echo "# Examples of use:"
    echo "# "
    echo "# Ex: './install.sh' "
    echo "# (Would default install with selinux enforcing configured and ipv6 disabled.)"
    echo "# "
    echo "# Ex: './install.sh disabled enabled master' "
    echo "# (Would install with selinux disabled and ipv6 enabled and ledgersmb lastest version.)"
    echo "# "
    echo "######################################################################################"
    echo " "
    exit 2
}

if [ $# > 0 ] && [ $# -eq 3 ]
then
    if [ $1 == 'enforcing' ] || [ $1 == 'disabled' ] || [ $1 == 'permissive' ]
    then
        export LEDGERSMB_SELINUX_MODE=$1
    else
        display_help
    fi
    if [ $2 == 'enabled' ] || [ $2 == 'disabled' ]
    then
        export LEDGERSMB_IPV6=$2
    else
        display_help
    fi
    if [ $3 == '1.7' ] || [ $3 == 'master' ] 
    then
        export LEDGERSMB_BRANCHVERSION=$3
    else
        display_help
    fi
elif [ $# -eq 0 ]
then
    export LEDGERSMB_SELINUX_MODE=enforcing
    export LEDGERSMB_IPV6=disabled
    export LEDGERSMB_BRANCHVERSION=master
else
    display_help
fi    


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


		

# DISABLE SELINUX IF NECESSARY
if [ $LEDGERSMB_SELINUX_MODE == 'disabled' ]
then 
	echo "SETTING SELINUX TO DISABLED..."
	sleep 2
	setenforce 0
	sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
elif [ $LEDGERSMB_SELINUX_MODE == 'permissive' ]
then 
	echo "SETTING SELINUX TO PERMISSIVE..."
	sleep 2
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

#################################################################################################
### STEP 2 ######################################################################################
#################################################################################################
clear
echo " "
echo "-> INSTALLER STEP 2 INITIATED : SYSTEM UPDATE"
echo " "
sleep 3

# UPDATE THE SYSTEM
dnf -y update



#################################################################################################
### STEP 3 ######################################################################################
#################################################################################################
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
git clone --recurse -b $LEDGERSMB_BRANCHVERSION  https://github.com/ledgersmb/LedgerSMB /usr/local/ledgersmb
chown -R apache:apache /usr/local/ledgersmb/UI
cp /usr/local/ledgersmb/doc/conf/ledgersmb.conf.default /usr/local/ledgersmb/ledgersmb.conf
cp /usr/local/ledgersmb/doc/conf/systemd/ledgersmb_starman.service /etc/systemd/system/



#################################################################################################
### STEP 4 ######################################################################################
#################################################################################################
clear
echo " "
echo "-> INSTALLER STEP 4 INITIATED : HTTP, HTTPS AND LETENCRYPT"
echo " "
sleep 3

# HTTPD AND LETSENCRYPT
cat >/etc/httpd/conf.d/ledgersmb.conf <<EOL
<VirtualHost *:80>
  ServerName $LEDGERSMB_HOSTNAME
  ServerAlias $LEDGERSMB_HOSTNAME
  DocumentRoot /usr/local/ledgersmb/UI
  <Directory /usr/local/ledgersmb/UI>
      Options -Indexes +FollowSymLinks
      AllowOverride All
  </Directory>
  ErrorLog /var/log/httpd/ledgersmb-error.log
  CustomLog /var/log/httpd/ledgersmb-access.log combined
</VirtualHost>
EOL

systemctl restart httpd


#### 0010 - LET ENCRYPTS PART 1 : 
dnf -y install mod_ssl openssl yum-utils
dnf -y install python3-virtualenv python36-devel augeas-libs libffi-devel platform-python-devel python-rpm-macros python3-rpm-generators python3-wheel-wheel
openssl req -newkey rsa:4096 -x509 -sha256 -days 36500 -nodes -out /etc/pki/tls/certs/localhost.crt -keyout /etc/pki/tls/private/localhost.key -subj "$LEDGERSMB_SSL_PARAMETERS"
wget https://dl.eff.org/certbot-auto
sudo mv certbot-auto /usr/local/bin/certbot-auto
sudo chown root /usr/local/bin/certbot-auto
sudo chmod 0755 /usr/local/bin/certbot-auto
sudo /usr/local/bin/certbot-auto --apache -m $LEDGERSMB_LETENCRYPTS_EMAILADDR --agree-tos -n -d $LEDGERSMB_HOSTNAME
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null
systemctl restart httpd

#### 0011 - HTTPD PART 3: RESETUP HTTP AND HTTPS

cat >/etc/httpd/conf.d/ledgersmb.conf <<EOL
<VirtualHost *:80>
  ServerName $LEDGERSMB_HOSTNAME
  ServerAlias $LEDGERSMB_HOSTNAME
  DocumentRoot /usr/local/ledgersmb/UI
  <Directory /usr/local/ledgersmb/UI>
      Options -Indexes +FollowSymLinks
      AllowOverride All
  </Directory>
  ErrorLog /var/log/httpd/ledgersmb-error.log
  CustomLog /var/log/httpd/ledgersmb-access.log combined
</VirtualHost>
EOL

cat >/etc/httpd/conf.d/ledgersmb-le-ssl.conf <<EOL
<IfModule mod_ssl.c>
<VirtualHost *:443>
  ServerName $LEDGERSMB_HOSTNAME
  ServerAlias $LEDGERSMB_HOSTNAME
  DocumentRoot /usr/local/ledgersmb/UI
  <Directory /usr/local/ledgersmb/UI>
      Options -Indexes +FollowSymLinks
      AllowOverride All
  </Directory>
  Protocols h2 http:/1.1
  <If "%{HTTP_HOST} == '$LEDGERSMB_HOSTNAME_AUTOWWW'">
    Redirect permanent / https://$LEDGERSMB_HOSTNAME/
  </If>
  ErrorLog /var/log/httpd/$LEDGERSMB_HOSTNAME.ssl-error.log
  CustomLog /var/log/httpd/$LEDGERSMB_HOSTNAME-access.log combined
  SSLEngine On
  SSLCertificateFile /etc/letsencrypt/live/$LEDGERSMB_HOSTNAME/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$LEDGERSMB_HOSTNAME/privkey.pem
  Include /etc/letsencrypt/options-ssl-apache.conf
  <Location "/">
    SSLRequireSSL
  </Location>
  Timeout 600
  ProxyTimeout 600
  RewriteEngine On
  RewriteRule "^/\$" "/login.pl" [R=301,L]
  RewriteRule "^/\." - [R=404,L]
  RewriteRule "\.conf\$" - [R=404,L]
  RewriteCond "%{REQUEST_FILENAME}" !-f
  RewriteCond "%{REQUEST_FILENAME}" !-d
  RewriteRule "^/(.*)" "http://127.0.0.1:5762/\$1" [P]
  ProxyPassReverse "/" "http://127.0.0.1:5762/"
</VirtualHost>
</IfModule>
EOL

systemctl restart httpd




#################################################################################################
### STEP 5 ######################################################################################
#################################################################################################
clear
echo " "
echo "-> INSTALLER STEP 5 INITIATED : CPAN PACKAGES AND LEDGERSMB PART 2"
echo " "
sleep 3

# CPAN INSTALLATION OF PACKAGES

mkdir ~/.cpan/
mkdir ~/.cpan/CPAN/
cat >/root/.cpan/CPAN/MyConfig.pm <<EOL
\$CPAN::Config = {
  'applypatch' => q[],
  'auto_commit' => q[0],
  'build_cache' => q[100],
  'build_dir' => q[/root/.cpan/build],
  'build_dir_reuse' => q[0],
  'build_requires_install_policy' => q[yes],
  'bzip2' => q[/usr/bin/bzip2],
  'cache_metadata' => q[1],
  'check_sigs' => q[0],
  'cleanup_after_install' => q[0],
  'colorize_output' => q[0],
  'commandnumber_in_prompt' => q[1],
  'connect_to_internet_ok' => q[1],
  'cpan_home' => q[/root/.cpan],
  'ftp_passive' => q[1],
  'ftp_proxy' => q[],
  'getcwd' => q[cwd],
  'gpg' => q[/usr/bin/gpg],
  'gzip' => q[/usr/bin/gzip],
  'halt_on_failure' => q[0],
  'histfile' => q[/root/.cpan/histfile],
  'histsize' => q[100],
  'http_proxy' => q[],
  'inactivity_timeout' => q[0],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[0],
  'keep_source_where' => q[/root/.cpan/sources],
  'load_module_verbosity' => q[none],
  'make' => q[/usr/bin/make],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'make_install_make_command' => q[/usr/bin/make],
  'makepl_arg' => q[],
  'mbuild_arg' => q[],
  'mbuild_install_arg' => q[],
  'mbuild_install_build_command' => q[./Build],
  'mbuildpl_arg' => q[],
  'no_proxy' => q[],
  'pager' => q[/usr/bin/less],
  'patch' => q[/usr/bin/patch],
  'perl5lib_verbosity' => q[none],
  'prefer_external_tar' => q[1],
  'prefer_installer' => q[MB],
  'prefs_dir' => q[/root/.cpan/prefs],
  'prerequisites_policy' => q[follow],
  'recommends_policy' => q[1],
  'scan_cache' => q[atstart],
  'shell' => q[/bin/bash],
  'show_unparsable_versions' => q[0],
  'show_upload_date' => q[0],
  'show_zero_versions' => q[0],
  'suggests_policy' => q[0],
  'tar' => q[/usr/bin/tar],
  'tar_verbosity' => q[none],
  'term_is_latin' => q[1],
  'term_ornaments' => q[1],
  'test_report' => q[0],
  'trust_test_report_history' => q[0],
  'unzip' => q[/usr/bin/unzip],
  'urllist' => [q[http://www.cpan.org/]],
  'use_prompt_default' => q[0],
  'use_sqlite' => q[0],
  'version_timeout' => q[15],
  'wget' => q[/usr/bin/wget],
  'yaml_load_code' => q[0],
  'yaml_module' => q[YAML],
};
1;
__END__
EOL

#### 0013 - CPAN - PART 2 - IN ORDER
cpan install App:Cpan
cpan install PGObject PGObject::Type::BigFloat Number::Format Config::IniFiles PGObject::Simple
cpan install MIME::Lite Moose HTTP::Exception PGObject::Simple::Role MooseX::NonMoose File::MimeInfo
cpan install PGObject::Type::ByteString Plack::Builder::Conditionals Plack::Middleware::Pod
cpan install Log::Log4perl Locale::Maketext::Lexicon DateTime::Format::Strptime PGObject::Type::DateTime
cpan install CGI::Emulate::PSGI CGI::Simple Digest::MD5 Encode File::Temp HTTP::Status List::Util Locale::Country Log::Log4Perl Mime::Base64 Try::Tiny Version::Compare
cpan install Net::Server XML::Parser XML::SAX::Expat XML::Simple
cpan install Plack::Middleware::Lint
cpan install Carp




#################################################################################################
### STEP 6 ######################################################################################
#################################################################################################
clear
echo " "
echo "-> INSTALLER STEP 6 INITIATED : LEDGERSMB FINAL PART, UGLIFY-JS, DOJO"
echo " "
sleep 3

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

# REMOVE ENVIRONMENT CONFIGURATION
. REMOVE_CONFIGURATION

clear
echo "Installation is (should be) complete"
echo " "
echo "Please open a compatible browser such as Mozilla Firefox, and point it to https://$LEDGERSMB_HOSTNAME/setup.pl to start using LedgerSMB"
echo " "
echo "This script was written by Steve Arbour"
echo " "
echo " "
echo "***************************************************************************************"
echo "***************************************************************************************"
echo "** WARNING THE SYSTEM WILL NOW REBOOT IN 15 SECONDS"
echo "***************************************************************************************"
echo "***************************************************************************************"
sleep 15
reboot




