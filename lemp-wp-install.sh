#!/bin/bash


# This script automates the creation of a LEMP stack (Linux, Nginx, Mysql, PHP)
# and then brings a fresh wordpress pre-install on top of it.
# The main goal atm is to gain time when testing some stuff in VMs
# so it's not really recommended to use it in production yet.
# A more polished and generic script will follow later.

# At one point the script will ask you several infos such as :
#
# - The name you would like to use for the website install
#   (e.g : 'example.com' or 'blog')
#
# - A new password for the database user 'root'
#   (part of the automated 'mysql_secure_install' process)
#
# - A name for the wordpress db and a username/password to connect to it
#   (you'll need those two when finalizing the wp install)


# Check if user has root privileges
if [ "$EUID" -ne 0 ]
    then echo "Run it as root"
    exit
fi

# All the output is hidden while installing the LEMP stack to get a
# fancier installer. Which may look like a bad practice but if anything
# goes wrong we're screwd anyway as it's a 'one shot' script.

echo
echo "LEMP stack install"
echo "##################"
echo

echo -n "Installing nginx... "
apt-get install -y nginx > /dev/null && echo "Done"

echo -n "Installing php7.0 modules... "
apt-get install -y \
    php7.0-common \
    php7.0-readline \
    php7.0-fpm \
    php7.0-cli \
    php7.0-gd \
    php7.0-mysql \
    php7.0-mcrypt \
    php7.0-curl \
    php7.0-mbstring \
    php7.0-opcache \
    php7.0-json \
    > /dev/null && echo "Done"

echo -n "Installing mariadb-server... "
apt-get install -y mariadb-server > /dev/null 2> /dev/null && echo "Done"


echo
echo "Config starts here"
echo "##################"
echo

# Which name/domain name to use for the website install
echo -n "Enter the website's name : "
read website_name

# Creating nginx config for the website
# Need to escape special char '$' on each line with a backslash '\'
# Otherwise bash will treat it as a variable and will cut the line
cat > /etc/nginx/sites-available/$website_name <<EOF
server {
    server_name $website_name;
    listen 80;
    root /var/www/html/$website_name;
    access_log /var/log/nginx/${website_name}_access.log;
    error_log /var/log/nginx/${website_name}_error.log;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
    }

    location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
        access_log off;
        expires max;
    }

    location ~ /\.ht {
        deny  all;
    }

    location ~ \.php$ {
        fastcgi_index index.php;
        fastcgi_keep_conn on;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

# Creating a symlink to activate the site
sudo ln -s /etc/nginx/sites-available/$website_name /etc/nginx/sites-enabled/$website_name


# Deleting nginx default config
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
rm /var/www/html/index.nginx-debian.html

systemctl restart nginx


# Tuning php-fpm settings
sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php/7.0/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 128M/" /etc/php/7.0/fpm/php.ini
sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/7.0/fpm/php.ini
sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/7.0/fpm/php.ini

# Moving original php-fpm config file and creating a new one
mv /etc/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf.org

# Filling new php-fpm config file with params
cat > /etc/php/7.0/fpm/pool.d/www.conf <<EOF
[www]
user = www-data
group = www-data
listen = /run/php/php7.0-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0666
pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s
pm.max_requests = 200
chdir = /
EOF

systemctl restart php7.0-fpm


# By default, the mariadb install is not secured, at all. So we automate
# several security tasks such as :
#
# - Changing the password of the user 'root' (blank by default)
# - Deleting the user with a blank name (anonymous login)
# - Restricting the db access to the localhost only
# - Deleting the database 'test'
#
# Equivalent of the interactive version when using 'mysql_secure_install'
# https://bertvv.github.io/notes-to-self/2015/11/16/automating-mysql_secure_installation/

echo -n "Enter a DB password for the root user : "
read -s db_root_passwd
echo

mysql --user=root <<EOF
UPDATE mysql.user SET Password=PASSWORD('${db_root_passwd}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Interactively creating a db for wordpress and corresponding user/password
# Needed later on when finalizing the wordpress install
echo -n "Enter a name for the wordpress db : "
read wp_db_name
echo -n "Choose a username for the db : "
read wp_user
echo -n "Choose a password for the user : "
read -s wp_user_passwd
echo
echo

mysql -u 'root' --password='${db_root_passwd}' --database='' <<EOF
CREATE DATABASE $wp_db_name;
GRANT ALL PRIVILEGES ON wpdb.* TO '${wp_user}'@'localhost' IDENTIFIED BY '${wp_user_passwd}';
FLUSH PRIVILEGES;
EOF

# Creating the website folder than will contain the wordpress install
mkdir /var/www/html/$website_name

# Downloading and extracting wordpress in the website folder
wget -q -O - http://wordpress.org/latest.tar.gz | sudo tar -xzf - --strip 1 -C /var/www/html/$website_name

# Configuring permissions for the wordpress install so nginx can access it
chown www-data: -R /var/www/html/$website_name

echo "All done."


