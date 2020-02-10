#!/bin/bash

WORKING_INSTALLATION_PATH="`dirname \"$0\"`"
WORKING_INSTALLATION_PATH="`( cd \"$WORKING_INSTALLATION_PATH\" && pwd )`"
. $WORKING_INSTALLATION_PATH/CONFIGURATION

clear
echo "*** PLEASE WAIT - INSTALLATION IN PROGRESS . . ."
echo " "
sleep $INSTALLER_SLEEP_ON_BOOT
echo "*** INSTALLER STEP 4 INITIATED"
echo " "

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
sleep 10
wget https://dl.eff.org/certbot-auto
sudo mv certbot-auto /usr/local/bin/certbot-auto
sudo chown root /usr/local/bin/certbot-auto
sudo chmod 0755 /usr/local/bin/certbot-auto
sudo /usr/local/bin/certbot-auto --apache -m $LEDGERSMB_LETENCRYPTS_EMAILADDR --agree-tos -n -d $LEDGERSMB_HOSTNAME
sleep 10
echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null
systemctl restart httpd
sleep 10
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


# PREPARING NEXT BOOT
sed -i '/step4.sh/d' /etc/rc.local
cat >>/etc/rc.local <<EOL
$WORKING_INSTALLATION_PATH/step5.sh
EOL

# REMOVE ENVIRONMENT CONFIGURATION
. $WORKING_INSTALLATION_PATH/REMOVE_CONFIGURATION

reboot

# END OF SCRIPT

