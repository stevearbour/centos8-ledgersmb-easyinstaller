#!/bin/bash

function display_help() {
    echo " "
    echo -e "\e[34m###############################################################################\e[0m"
    echo -e "\e[34m#\e[0m \e[91;1mCentOS 8 - LedgerSMB - Easy Installer \e[0m"
    echo -e "\e[34m###############################################################################\e[0m"
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m#\e[0m Usage: install.sh \e[93m<selinux_mode> <ipv6_mode> <ledgersmb_git_branch>\e[0m"
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m#\e[0m Valid values for <selinux_mode> \e[92menforcing\e[0m, \e[92mpermissive\e[0m, \e[92mdisabled\e[0m"
    echo -e "\e[34m#\e[0m (Default is: \e[93menforcing\e[0m)"
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m#\e[0m Valid values for <ipv6_mode> \e[92menabled\e[0m, \e[92mdisabled\e[0m"
    echo -e "\e[34m#\e[0m (Default is: \e[93mdisabled\e[0m)"
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m#\e[0m Valid values for <ledgersmb_git_branch> \e[92m1.5\e[0m, \e[92m1.6\e[0m, \e[92m1.7\e[0m, \e[92mstable\e[0m, \e[92mmaster\e[0m"
    echo -e "\e[34m#\e[0m (Default is: \e[93mstable\e[0m)"
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m#\e[0m Examples of use:"
    echo -e "\e[34m#\e[0m Ex: '\e[93m./install.sh\e[0m' "
    echo -e "\e[34m#\e[0m (Would default install with selinux enforcing configured and ipv6 disabled "
    echo -e "\e[34m#\e[0m and ledgersmb 1.7.* stable version.)"
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m#\e[0m Ex: '\e[93m./install.sh disabled enabled 1.7\e[0m' "
    echo -e "\e[34m#\e[0m (Would install with selinux disabled and ipv6 enabled and ledgersmb 1.7.x "
    echo -e "\e[34m#\e[0m lastest stable version.)"
    echo -e "\e[34m#\e[0m "
    echo -e "\e[34m###############################################################################\e[0m"
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
    if [ $3 == '1.5' ] || [ $3 == '1.6' ] || [ $3 == '1.7' ]  || [ $3 == 'master' ] || [ $3 == 'stable' ]
    then
        export LEDGERSMB_BRANCHVERSION=$3
    else
        display_help
    fi
elif [ $# -eq 0 ]
then
    export LEDGERSMB_SELINUX_MODE=enforcing
    export LEDGERSMB_IPV6=disabled
    export LEDGERSMB_BRANCHVERSION=stable
else
    display_help
fi    


clear
echo -e "\e[34m********************************************************************************\e[0m"
echo -e " \e[31m\e[1mCentOS 8 - LedgerSMB - Easy Installer\e[0m "
echo -e "\e[34m********************************************************************************\e[0m"
echo " "
echo -e " Installation script written by \e[93mSteve Arbour\e[0m"
echo -e " Special thanks go to \e[93mehuelsmann hasorli dcg Yves\e[0m"
echo " Please report any problem so that I try to improve this installation script."
echo " "
echo " Tested with CentOS 8.1-1.1911.0.8.el8.x86_64 (4.18.0-147.5.1.el8_1.x86_64)"
echo " Installation will start in 10 seconds... "
echo " "
echo -e "\e[34m********************************************************************************\e[0m"
echo -e "\e[31m\e[1m WARNING : Please do not touch or operate the system during the installation, \e[0m"
echo -e "\e[31m\e[1m it should reboot at the end and be ready to access setup.pl \e[0m"
echo -e "\e[34m********************************************************************************\e[0m"
echo " "
sleep 10

WORKING_INSTALLATION_PATH="`dirname \"$0\"`"
WORKING_INSTALLATION_PATH="`( cd \"$WORKING_INSTALLATION_PATH\" && pwd )`"
. $WORKING_INSTALLATION_PATH/CONFIGURATION

# DISABLE SELINUX IF NECESSARY
if [ $LEDGERSMB_SELINUX_MODE == 'disabled' ]
then 
	echo -e "\e[96mSETTING SELINUX TO DISABLED...\e[0m"
    echo -e " "
	sleep 1
	setenforce 0
	sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
elif [ $LEDGERSMB_SELINUX_MODE == 'permissive' ]
then 
	echo -e "\e[96mSETTING SELINUX TO PERMISSIVE...\e[0m"
    echo -e " "
    sleep 1
    
    dnf -y install selinux-policy-devel policycoreutils-devel
    sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
    setenforce 0	

    semanage port -a -t http_port_t -p tcp 80
    semanage port -a -t http_port_t -p tcp 443
    semanage port -a -t http_port_t -p tcp 5762
    setsebool -P httpd_can_network_connect 1
    setsebool -P domain_kernel_load_modules 1
elif [ $LEDGERSMB_SELINUX_MODE == 'enforcing' ]
then 
	echo -e "\e[96mCONFIGURING SELINUX TO ALLOW LEDGERSMB...\e[0m"
    echo -e " "
    sleep 1
    
    dnf -y install selinux-policy-devel policycoreutils-devel
    sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/g' /etc/selinux/config
    setenforce 0

    semanage port -a -t http_port_t -p tcp 80
    semanage port -a -t http_port_t -p tcp 443
    semanage port -a -t http_port_t -p tcp 5762
    setsebool -P httpd_can_network_connect 1
    setsebool -P domain_kernel_load_modules 1
   
fi

# MODIFYING GRUB TO DISABLE IPV6 IF NECESSARY
if [ $LEDGERSMB_IPV6 == 'disabled' ]
then
	echo -e "\e[96mDISABLING IPv6...\e[0m"
    echo -e " "
    sleep 1
	sysctl -w net.ipv6.conf.all.disable_ipv6=1
    echo "1" > /proc/sys/net/ipv6/conf/all/disable_ipv6  
	printf "\nGRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX ipv6.disable=1\"" >> /etc/default/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
	grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
fi


sleep $LEDGERSMB_DEBUGGING_DELAY_BTW_STEPS
#################################################################################################
### STEP 2 ######################################################################################
#################################################################################################
clear
echo " "
echo -e "\e[93mINSTALLER STEP 2 INITIATED : SYSTEM UPDATE\e[0m"
echo " "
sleep 3

echo -e "\e[96mENABLE CENTOS POWERTOOLS REPO\e[0m"
echo " "
sleep 1
sudo sed -i 's/^enabled=0.*/enabled=1/g' /etc/yum.repos.d/CentOS-PowerTools.repo

echo -e "\e[96mUPDATING THE SYSTEM VIA DNF\e[0m"
echo " "
sleep 1
dnf -y update


sleep $LEDGERSMB_DEBUGGING_DELAY_BTW_STEPS
#################################################################################################
### STEP 3 ######################################################################################
#################################################################################################
clear
echo " "
echo -e "\e[93mINSTALLER STEP 3 INITIATED : PACKAGES AND NET/DB/LEDGERSMB SERVICE INSTALLATION PART 1\e[0m"
echo " "
sleep 3

echo -e "\e[96mINSTALLATION OF ADDITIONNAL PACKAGES VIA DNF\e[0m"
echo " "
sleep 1
dnf -y install nano gcc make wget git net-tools cpan cpanminus perl epel-release
dnf -y install httpd 
dnf -y install postgresql postgresql-devel postgresql-server
dnf -y install perl-CGI-Emulate-PSGI perl-Config-IniFiles perl-DBD-Pg perl-DBI perl-Digest-MD5 perl-Locale-Maketext perl-Log-Log4perl perl-MIME-Base64 perl-MIME-Lite perl-Math-BigInt-GMP perl-Moose perl-Plack perl-Template-Toolkit perl-MooseX-NonMoose perl-XML-Simple texlive perl-JSON-MaybeXS expat-devel texlive-latex 
dnf -y install redhat-lsb
dnf -y install nodejs nodejs-devel nodejs-packaging nodejs-docs
dnf -y install java-latest-openjdk
dnf -y install perl-File-MimeInfo 
dnf -y install perl-Plack-Test   
dnf -y install perl-DateTime-Format-Strptime
dnf -y install perl-autobox-List-Util
dnf -y install perl-Net-Server

echo -e "\e[96mCONFIGURING FIREWALLD\e[0m"
echo " "
sleep 1
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
systemctl restart firewalld

echo -e "\e[96mACTIVATE HTTPD\e[0m"
echo " "
sleep 1
systemctl enable httpd
systemctl start httpd

echo -e "\e[96mPOSTGRESQL\e[0m"
echo " "
sleep 1
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


echo -e "\e[96mLEDGERSMB: PART 1\e[0m"
echo " "
sleep 1
cd /usr/local && rm -rf /usr/local/ledgersmb
git clone https://github.com/ledgersmb/LedgerSMB /usr/local/ledgersmb && cd /usr/local/ledgersmb

if [ $LEDGERSMB_BRANCHVERSION != 'master' ] && [ $LEDGERSMB_BRANCHVERSION != 'stable' ] 
then
    LEDGERSMB_VERSION=$(git tag | grep "^$LEDGERSMB_BRANCHVERSION" | grep -v '[a-zA-Z]' | sort -V | tail -n1)
elif [ $LEDGERSMB_BRANCHVERSION == 'stable' ] 
then
    LEDGERSMB_VERSION=$(git tag | grep -v '[a-zA-Z]' | sort -V | tail -n1)
elif [ LEDGERSMB_VERSION == 'master' ] 
then
    LEDGERSMB_VERSION='master'
fi

echo -e "\e[93mLedgerSMB Version : $LEDGERSMB_VERSION will be installed . . .\e[0m"
echo " "
sleep 1
sleep 3
git submodule deinit . && git checkout $LEDGERSMB_VERSION && git submodule update --init --recursive
chown -R apache:apache /usr/local/ledgersmb/UI

# REMOVE ANY EXISTING CONFIGURATION FILES AND EXISTING SERVICE SYSTEMD FILE
rm -rf /etc/systemd/system/ledgersmb_starman.service && rm -rf /usr/local/ledgersmb/ledgersmb.conf

# COPY DEFAULT CONFIGURATION FILE AND SERVICE SYSTEMD FILE FOR THAT BRANCH
if [ $LEDGERSMB_BRANCHVERSION == "1.5" ]
then
    cp /usr/local/ledgersmb/conf/systemd/starman-ledgersmb.service /etc/systemd/system/ledgersmb_starman.service
    cp /usr/local/ledgersmb/conf/ledgersmb.conf.default /usr/local/ledgersmb/ledgersmb.conf
elif [ $LEDGERSMB_BRANCHVERSION == "1.6" ]
then
    cp /usr/local/ledgersmb/conf/systemd/ledgersmb_starman.service /etc/systemd/system/ledgersmb_starman.service
    cp /usr/local/ledgersmb/conf/ledgersmb.conf.default /usr/local/ledgersmb/ledgersmb.conf
elif [ $LEDGERSMB_BRANCHVERSION == "1.7" ]
then
    cp /usr/local/ledgersmb/doc/conf/systemd/ledgersmb_starman.service /etc/systemd/system/ledgersmb_starman.service
    cp /usr/local/ledgersmb/doc/conf/ledgersmb.conf.default /usr/local/ledgersmb/ledgersmb.conf
else
    cp /usr/local/ledgersmb/doc/conf/systemd/ledgersmb_starman.service /etc/systemd/system/ledgersmb_starman.service
    cp /usr/local/ledgersmb/doc/conf/ledgersmb.conf.default /usr/local/ledgersmb/ledgersmb.conf
fi

# IPV6 FIX, CHANGE LOCALHOST TO 127.0.0.1 IN THE SYSTEMD FILE
# This is required, because otherwise it will default to ::1
# And we do not want this if we disable IPv6 
if [ $LEDGERSMB_IPV6 == 'disabled' ]
then
    echo -e "\e[96mIPV6 FIX, CHANGE LOCALHOST TO 127.0.0.1 IN THE SYSTEMD FILE\e[0m"
    echo " "
    sudo sed -i 's/--listen localhost:5762.*/--listen 127.0.0.1:5762 \\/g' /etc/systemd/system/ledgersmb_starman.service
fi

sleep $LEDGERSMB_DEBUGGING_DELAY_BTW_STEPS
#################################################################################################
### STEP 4 ######################################################################################
#################################################################################################
clear
echo " "
echo -e "\e[93mINSTALLER STEP 4 INITIATED : HTTP, HTTPS AND LETENCRYPT\e[0m"
echo " "
sleep 3

echo -e "\e[96mHTTPD AND LETSENCRYPT\e[0m"
echo " "
sleep 1
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

#Empty any instance of /etc/httpd/conf.d/ledgersmb-le-ssl.conf
echo " " > /etc/httpd/conf.d/ledgersmb-le-ssl.conf 
          
systemctl restart httpd



echo -e "\e[96mLETSENCRYPT: PART 1\e[0m" 
echo " "
sleep 1
dnf -y install mod_ssl openssl yum-utils
dnf -y install python3-virtualenv python36-devel augeas-libs libffi-devel platform-python-devel python-rpm-macros python3-rpm-generators python3-wheel-wheel
openssl req -newkey rsa:4096 -x509 -sha256 -days 36500 -nodes -out /etc/pki/tls/certs/localhost.crt -keyout /etc/pki/tls/private/localhost.key -subj "$LEDGERSMB_SSL_PARAMETERS"
wget https://dl.eff.org/certbot-auto
sudo mv certbot-auto /usr/local/bin/certbot-auto
sudo chown root /usr/local/bin/certbot-auto
sudo chmod 0755 /usr/local/bin/certbot-auto
if [ $LEDGERSMB_LETSENCRYPT_DRYRUN -eq 1 ]
then
    sudo /usr/local/bin/certbot-auto --dry-run --apache -m $LEDGERSMB_LETENCRYPTS_EMAILADDR --agree-tos -n -d $LEDGERSMB_HOSTNAME 
else                            
    sudo /usr/local/bin/certbot-auto --apache -m $LEDGERSMB_LETENCRYPTS_EMAILADDR --agree-tos -n -d $LEDGERSMB_HOSTNAME
fi
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null
systemctl restart httpd

sleep 60

echo -e "\e[96mHTTPD PART 3: RESETUP HTTP AND HTTPS\e[0m"
echo " "
sleep 1
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



sleep $LEDGERSMB_DEBUGGING_DELAY_BTW_STEPS
#################################################################################################
### STEP 5 ######################################################################################
#################################################################################################
clear
echo " "
echo -e "\e[93mINSTALLER STEP 5 INITIATED : CPAN PACKAGES AND LEDGERSMB PART 2\e[0m"
echo " "
sleep 3

echo -e "\e[96mCPAN PART 1: CREATION OF A DEFAULT FILE FOR CPAN\e[0m"
echo " "
sleep 1
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

echo -e "\e[96mCPAN PART 2: PACKAGES INSTALLATION, IN ORDER\e[0m"
echo " "
sleep 1
#cpan install App:Cpan
#cpan install PGObject PGObject::Type::BigFloat Number::Format Config::IniFiles PGObject::Simple
#cpan install MIME::Lite Moose HTTP::Exception PGObject::Simple::Role MooseX::NonMoose File::MimeInfo
#cpan install PGObject::Type::ByteString Plack::Builder::Conditionals Plack::Middleware::Pod
#cpan install Log::Log4perl Locale::Maketext::Lexicon DateTime::Format::Strptime PGObject::Type::DateTime
#cpan install CGI::Emulate::PSGI CGI::Simple Digest::MD5 Encode File::Temp HTTP::Status List::Util Locale::Country Log::Log4Perl Mime::Base64 Try::Tiny Version::Compare
#cpan install Net::Server XML::Parser XML::SAX::Expat XML::Simple
#cpan install Plack::Middleware::Lint Carp


#cpan install App:Cpan
#cpan install PGObject PGObject::Type::BigFloat Number::Format PGObject::Simple
#cpan install HTTP::Exception PGObject::Simple::Role 
#cpan install PGObject::Type::ByteString Plack::Builder::Conditionals Plack::Middleware::Pod
#cpan install Locale::Maketext::Lexicon PGObject::Type::DateTime
#cpan install CGI::Simple HTTP::Status Locale::Country Version::Compare
#cpan install XML::SAX::Expat 
#cpan install Plack::Middleware::Lint




sleep $LEDGERSMB_DEBUGGING_DELAY_BTW_STEPS
#################################################################################################
### STEP 6 ######################################################################################
#################################################################################################
clear
echo " "
echo -e "\e[93mINSTALLER STEP 6 INITIATED : LEDGERSMB FINAL PART, UGLIFY-JS, DOJO\e[0m"
echo " "
sleep 3

echo -e "\e[96mLEDGERSMB\e[0m"
echo " "
sleep 1
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


echo -e "\e[96mSELINUX\e[0m"
echo " "
sleep 1
if [ $LEDGERSMB_SELINUX_MODE == 'enforcing' ]
then 
    echo -e "\e[96mCONFIGURING SELINUX TO ALLOW LEDGERSMB...\e[0m"
    " "
    sleep 1
    setenforce 1
fi


echo -e "\e[96mEND OF INSTALLATION\e[0m"
echo " "
sleep 1
systemctl daemon-reload
systemctl enable postgresql
systemctl enable httpd
systemctl enable ledgersmb_starman
systemctl restart postgresql
systemctl restart httpd
systemctl restart ledgersmb_starman


clear
echo " Installation is (should be) complete"
echo " "
echo " Please open a compatible browser such as Mozilla Firefox, "
echo -e " and point it to \e[93mhttps://$LEDGERSMB_HOSTNAME/setup.pl\e[0m to start "
echo " using LedgerSMB after this server have rebooted."
echo " "
echo " "
echo " "
echo -e " \e[31m*** SECURITY WARNING ***\e[0m"
echo -e " \e[93mOnce the installer finish and you have tested the \e[0m" 
echo -e " \e[93minstallation, be sure to remove the CONFIGURATION file \e[0m"
echo -e " \e[93mbecause it contain your LSMB_DBADMIN password used for \e[0m" 
echo -e " \e[93minitial installation\e[0m"
echo " "
echo " "
echo -e " This script was written by \e[93mSteve Arbour\e[0m"
echo " "
echo " "
echo -e " ******************************************************"
echo -e " ** \e[31mWARNING THE SYSTEM WILL NOW REBOOT IN 15 SECONDS\e[0m **"
echo -e " ******************************************************"
. $WORKING_INSTALLATION_PATH/REMOVE_CONFIGURATION    
sleep 15
reboot




