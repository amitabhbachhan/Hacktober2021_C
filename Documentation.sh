# Linux Project
# Case1 : Create a Single tier Architect enviroment for CMS like Wordpress, Magento App on AWS Insatnce.

#Server Configure Details:

#AWS Instance Type: t2.micro
#AMI or Server OS: CentOS 7 (x86_64) - with Updates HVM

#Disk Layout: 

#	-- Disk1: 8GB for / (for the root volume)
#   -- Attach 2 more encrypted Volume with disk accidental termination protection policy at least 4GB Size of volume when you lauched your instance .

#   -- Make these volume LVM type for future app data size grow requirement 
yum install lvm2 -y
pvcreate /dev/xvdb /dev/xvdc
vgcreate volumegroup1 /dev/xvdb
vgcreate volumegroup2 /dev/xvdc
lvcreate --name mylvm1 --size 3.9G volumegroup1
lvcreate --name mylvm2 --size 3.9G volumegroup2

#   -- Format with xfs file system 
mkfs.xfs /dev/volumegroup1/mylvm1
mkfs.xfs /dev/volumegroup2/mylvm2

#   -- Disk2: 4GB for Home ( For web data, mount this on /home2 with "no execution binary" security flag)
mkdir /home2
mount /dev/volumegroup1/mylvm1 /home2

#   -- Disk3: 4Gb for MySQL ( mount this drive on /var/lib/mysql "no execution binary" before installation of mariadb server )
mkdir /var/lib/mysql
mount /dev/volumegroup2/mylvm2 /var/lib/mysql

# Entry in fstab
cat <<EOF >> /etc/fstab
/dev/volumegroup1/mylvm1 /home2 xfs defaults,noexec 0 0
/dev/volumegroup2/mylvm2 /var/lib/mysql xfs defaults,noexec 0 0
EOF
	
# Disable Selinux
sed   -i   's/enforcing/disabled/g'   /etc/selinux/config
setenforce 0

# Set timezone to IST 
timedatectl set-timezone Asia/Kolkata

# Configure your motd file on server to get more information dynamically about server whenever we login.
cat <<EOF > /etc/motd.sh
#!/bin/sh
clear
echo "###############################################################
#                 Authorized access only!                     # 
# Disconnect IMMEDIATELY if you are not an authorized user!!! #
#         All actions Will be monitored and recorded          #
###############################################################"
                                                                                                                                                  
echo "+++++++++++++++++++++++++++++++++++++SERVER INFO+++++++++++++++++++++++++++++++++++++++++"                                                     
                                                                                                                                                     
cpu_info=$(cat /proc/cpuinfo | grep -w 'model name' | awk -F: '{print $2}')                                                                          
mem_info=$(cat /proc/meminfo | grep -w 'MemTotal' | awk -F: '{print $2/1024 "M"}')                                                                   
mem_free=$(cat /proc/meminfo | grep -w 'MemFree' | awk -F: '{print $2/1024 "M"}')                                                                    
swap_total=$(cat /proc/meminfo | grep -w 'SwapTotal' | awk -F: '{print $2/1024 "M"}')                                                                
swap_free=$(cat /proc/meminfo | grep -w 'SwapFree' | awk -F: '{print $2/1024 "M"}')                                                                  
disk_total=$(df -h --output=size | head -n 2 | tail -n 1)                                                                                            
disk_free=$(df -h --output=avail | head -n 2 | tail -n 1)                                                                                            
cpu_load=$(cat /proc/loadavg | head -c 15)                                                                                                           
distro=$(cat /etc/*-release | head -n 1)                                                                                                             
public_ip=$(curl ifconfig.co)                                                                                                                        
private_ip=$(hostname -i)                                                                                                                            
                                                                                                                                                     
echo "    CPU: $cpu_info"                                                                                                                            
echo "    Memory: $mem_info"                                                                                                                         
echo "    Swap: $swap_total"                                                                                                                         
echo "    Disk: $disk_total"                                                                                                                         
echo "    Distro: $distro"                                                                                                                           
echo "    CPU Load: $cpu_load"                                                                                                                       
echo "    Free Memory: $mem_free"                                                                                                                    
echo "    Free Swap: $swap_free"                                                                                                                     
echo "    Free Disk: $disk_free"                                                                                                                     
echo "    Public Address: $public_ip"                                                                                                                
echo "    Private Address: $private_ip"                                                                                                              
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"                                                   
                                                                                                                                                     
EOF

#make script executable
chmod +x /etc/motd.sh

#Append this script to /etc/profile in order to be executed as last command once a user login.
echo "/etc/motd.sh" >> /etc/profile

#Install basic utility like netstat, wget, vim, git, etc.
yum	install	vi	    -y
yum	install	git	    -y
yum	install	net-tools     -y
yum	install	wget	-y

# Update all your server packages.
yum update -y

# Reboot server
reboot


#Packages:

#Install Apache 2.4.x server with SSL and proxy module support
yum	install	httpd httpd-tools -y
#rpm -ql httpd : shows the installed packages and directories

systemctl	start	httpd.service
systemctl	enable	httpd.service
yum	install	mod_ssl  -y


#Install PHP v7.x with essential php modules like php-mysql, php-devel, php-mbstring etc which is required by Application.
yum install centos-release-scl   -y
yum     install     rh-php72-php     rh-php72-php-common     rh-php72-php-cli   rh-php72-php-devel     rh-php72-php-gd     rh-php72-php-json     rh-php72-php-mbstring     rh-php72-php-mysqlnd     rh-php72-php-opcache     rh-php72-php-zip sclo-php72-php-mcrypt     rh-php72-php-xml     rh-php72-php-intl  -y

#Symlink the PHP 7.2 Apache modules into place:
ln -s /opt/rh/httpd24/root/etc/httpd/conf.d/rh-php72-php.conf /etc/httpd/conf.d/
ln -s /opt/rh/httpd24/root/etc/httpd/conf.modules.d/15-rh-php72-php.conf /etc/httpd/conf.modules.d/
ln -s /opt/rh/httpd24/root/etc/httpd/modules/librh-php72-php7.so /etc/httpd/modules/
ln -s /opt/rh/rh-php72/root/usr/bin/php /usr/bin/php


# install MariaDB server
cat <<EOF > /etc/yum.repos.d/mariadb.repo
[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum install MariaDB-server MariaDB-client -y 
systemctl start mariadb
systemctl enable mariadb


# Increasing the max_allowed_packet to 1G
cat <<EOF >> /etc/my.cnf
[mysqldump]
max_allowed_packet=1G
EOF


#run mysql_secure_installation
#configure all information
#to run mysql
#mysql -u root -p
#password is centos



# MYSQL REQUIREMENTS
# open mariadb using 'mysql -u root -p' (password: centos)
# CREATE DATABASE wp;
# CREATE DATABASE magento;
# CREATE USER wp@localhost IDENTIFIED BY "centos";
# GRANT ALL ON wp.* TO wp@localhost;
# FLUSH PRIVILEGES;
# CREATE USER magento@localhost IDENTIFIED BY "centos";
# GRANT ALL ON magento.* TO magento@localhost;
# FLUSH PRIVILEGES;
# exit


#User Setup
useradd -b /home2 wp
useradd -b /home2 magento
mkdir /home2/magento/.ssh
touch /home2/magento/.ssh/authorized_keys
chmod 600 /home2/magento/.ssh/authorized_keys
chmod 700 /home2/magento/.ssh
mkdir /home2/wp/.ssh
touch /home2/wp/.ssh/authorized_keys
chmod 600 /home2/wp/.ssh/authorized_keys
chmod 700 /home2/wp/.ssh

#password less login
ssh-keygen -N "" -f /home2/magento/.ssh/key
cat /home2/magento/.ssh/key.pub >> /home2/magento/.ssh/authorized_keys

ssh-keygen -N "" -f /home2/wp/.ssh/key
cat /home2/wp/.ssh/key.pub >> /home2/wp/.ssh/authorized_keys

mkdir /home2/{wp,magento}/public_html

# change document root of magento and wp
cp /etc/httpd/conf/httpd.conf /home2/wp/
cp /etc/httpd/conf/httpd.conf /home2/magento/

# virtual host configuration of wp
cat <<EOF > /etc/httpd/conf.d/wp.conf
<VirtualHost *:80>
  ServerName abhinaybhatt-wp.adhocnw.com
  DocumentRoot /home2/wp/public_html/
  <Directory /home2/wp/public_html/>
      Options Indexes FollowSymLinks MultiViews
      AllowOverride All
      Order allow,deny
      allow from all
    Require all granted
  </Directory>
  ErrorLog /home2/wp/error.log
  CustomLog /home2/wp/access.log combined
</VirtualHost>
EOF

# virtual host configuration of magento
cat <<EOF > /etc/httpd/conf.d/magento.conf
<VirtualHost *:80>
  ServerName abhinaybhatt-magento.adhocnw.com
  DocumentRoot /home2/magento/public_html/
  <Directory /home2/magento/public_html/>
      Options Indexes FollowSymLinks MultiViews
      AllowOverride All
      Order allow,deny
      allow from all
    Require all granted
  </Directory>
  ErrorLog /home2/magento/error.log
  CustomLog /home2/magento/access.log combined
</VirtualHost>
EOF

# permissions for home and public_html
chmod 711 /home2
chmod 755 /home2/wp/public_html
chmod 755 /home2/magento/public_html

usermod -a -G apache wp
chown wp:apache /home2/wp/public_html -R
chmod 711 /home2/wp
chmod 2771 /home2/wp/public_html

usermod -a -G apache magento
chown magento:apache /home2/magento/public_html -R
chmod 711 /home2/magento
chmod 2771 /home2/magento/public_html



# Wordpress Setup
wget -P /tmp https://wordpress.org/latest.tar.gz
tar -xf /tmp/latest.tar.gz  -C  /home2/wp/public_html/
rm -rf  /tmp/latest.tar.gz
mv /home2/wp/public_html/wordpress/*   /home2/wp/public_html/
rm -rf  /home2/wp/public_html/wordpress/wget -P /tmp https://wordpress.org/latest.tar.gz

# Magento Setup 
wget -P /tmp https://github.com/magento/magento2/archive/2.1.0.tar.gz
tar -xf /tmp/2.1.0.tar.gz -C /home2/magento/public_html/
mv /home2/magento/public_html/magento2-2.1.0/* /home2/magento/public_html/
mv /home2/magento/public_html/magento2-2.1.0/.htaccess /home2/magento/public_html/
rm -rf /home2/magento/public_html/magento2-2.1.0









composer

























