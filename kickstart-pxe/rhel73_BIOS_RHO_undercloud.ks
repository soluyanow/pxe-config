#version=RHEL7
# 2017.12.08
# Kickstart for installing RHEL 7.3 on a BIOS firmware machine
# to be used as an undercloud node for Redhat Openstack Newton (10)
#
# This kickstart file assumes use of the RHEL 7.3 DVD iso

# System authorization information
auth --enableshadow --passalgo=sha512
#ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
# Use graphical install
graphical
# Firewall configuration
firewall --disabled
# RHO requires selinux to be enabled; selinux is enabled by default
#selinux --enabled
# reboot when install is complete
reboot

# CHANGEME
network  --hostname=undercloud.atto.org

# System timezone
timezone Asia/Seoul --isUtc
# Delete all partitions
clearpart --all --initlabel
# Delete MBR / GPT
zerombr
# System bootloader configuration
bootloader --location=mbr --boot-drive=sda

# Disk partitioning information
part /boot --fstype=ext4    --ondisk=sda --size=384
part pv.001    --fstype="lvmpv"  --ondisk=sda  --size=1 --grow
volgroup rhel73  --pesize=4096 pv.001
logvol swap    --fstype="swap"   --size=2048 --name=swap --vgname=rhel73
# root part will take up all available space:
logvol /       --fstype="xfs"    --size=1    --name=root --vgname=rhel73 --grow

# Password Hash (can be generated by the following python3 snippet:)
# python3 -c 'import crypt; print(crypt.crypt("yourpw", crypt.mksalt(crypt.METHOD_SHA512)))'
rootpw --iscrypted $6$N52J3aF.lVhii5W3$5sXiXrYvphFe2VHkwxLeUoZ/kO3GDMILUZPKbclzDcWU9MMdEog38cRpOkZ4pD3WEanY2abqHGn3bxgYnnurv0

# Add regular user
user --name attodev --groups=wheel --iscrypted --password=$6$N52J3aF.lVhii5W3$5sXiXrYvphFe2VHkwxLeUoZ/kO3GDMILUZPKbclzDcWU9MMdEog38cRpOkZ4pD3WEanY2abqHGn3bxgYnnurv0
# System services
services --enabled="chronyd"
services --disabled="NetworkManager"


%packages
chrony
deltarpm
parted
wget
%end

%post
# before executing the cmd's below, make sure that your PXE server
# has IP masquerading turned on in the public zone (wireless iface)
# so that traffic from the PXE client connected to the LAN port
# will be forwarded to the Internet

# To register your system with RedHat, you will have to run the
# 'subscription-manager' command from the CLI and do these manual steps:
#
# subscription-manager register --username <username> --password <password>
# subscription-manager list --available --all
# subscription-manager attach --pool=<poolID>

# Or just download and run this script from your PXE server
# (I added *.rhsm filetype to .gitignore)

/bin/wget http://10.10.10.97:8000/register-rhel7.rhsm 1>>/root/post_install.log 2>&1
/bin/wget http://10.10.10.97:8000/RHOP10_pool_register.rhsm 1>>/root/post_install.log 2>&1
/bin/bash register-rhel7.rhsm 1>>/root/post_install.log 2>&1
/bin/bash RHOP10_pool_register.rhsm 1>>/root/post_install.log 2>&1
/sbin/subscription-manager repos --enable rhel-7-server-rh-common-rpms 1>>/root/post_install.log 2>&1
/sbin/subscription-manager repos --enable rhel-7-server-extras-rpms 1>>/root/post_install.log 2>&1
#/sbin/subscription-manager repos --enable rhel-7-server-optional-rpms 1>>/root/post_install.log 2>&1
#/sbin/subscription-manager repos --enable rhel-7-server-supplementary-rpms 1>>/root/post_install.log 2>&1
/sbin/subscription-manager repos --enable rhel-ha-for-rhel-7-server-rpms 1>>/root/post_install.log 2>&1
/sbin/subscription-manager repos --enable rhel-7-server-openstack-10-rpms 1>>/root/post_install.log 2>&1

/bin/yum update -y
/bin/yum install -y screen vim-enhanced 1>>/root/post_install.log 2>&1
/bin/rm register-rhel7.rhsm 1>>/root/post_install.log 2>&1

%end
