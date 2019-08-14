#!/bin/bash

# Update and upgrade available packages
yum update -y && yum upgrade -y

# Install firewalld
yum install firewalld -y
systemctl enable firewalld
systemctl start firewalld

# Disable `selinux`
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config

# Change system limit configuration
echo "" >> /etc/sysctl.conf
echo "# virtual memory maximum map count" >> /etc/sysctl.conf
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
echo "" >> /etc/sysctl.conf
echo "# max open files (systemic limit)" >> /etc/sysctl.conf
echo "fs.file-max=65536" >> /etc/sysctl.conf
sysctl -p

echo "" >> /etc/security/limits.conf
echo "# ulimit -u 4096" >> /etc/security/limits.conf
echo "*               soft    nofile          4096" >> /etc/security/limits.conf
echo "" >> /etc/security/limits.conf
echo "# ulimit -n 65536" >> /etc/security/limits.conf
echo "*               hard    nofile          65536" >> /etc/security/limits.conf

# Reboot machine
shutdown -r
