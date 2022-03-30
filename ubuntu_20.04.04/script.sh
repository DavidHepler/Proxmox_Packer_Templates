# Apply updates and cleanup Apt cache
#
apt-get update ; apt-get -y dist-upgrade
apt-get install nfs-common git vim htop -y
apt-get -y autoremove
apt-get -y clean

echo Reset the machine-id value. This has known to cause issues with DHCP
#
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
echo Removing cloud.cfg.d/99-installer.cfg
rm /etc/cloud/cloud.cfg.d/99-installer.cfg
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Reset any existing cloud-init state
#
echo Running Cloud-init clean
cloud-init clean -s -l