#!/bin/bash
sudo apt-get update
sudo apt-get install -y php libapache2-mod-php php-mysql wget unzip
cd /tmp; wget https://wordpress.org/latest.zip
unzip latest.zip
sudo cp -a wordpress/* /var/www/html/
rm -rf /tmp/latest.zip /var/www/html/index.html /tmp/wordpress
sudo cd  /var/www/html/
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i 's/database_name_here/wp-data/' /var/www/html/wp-config.php
sed -i 's/username_here/wp-user/' /var/www/html/wp-config.php
sed -i 's/password_here/${database_password}/' /var/www/html/wp-config.php
sed -i 's/localhost/${database_ip}/' /var/www/html/wp-config.php
