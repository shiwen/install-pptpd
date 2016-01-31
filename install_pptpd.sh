#!/bin/bash

if [ $EUID -ne 0 ]
then
    >&2 echo "Please run as root"
    exit 1
fi

dir=`dirname $0`

# install dependencies
yum -y install ppp

# rpm install
rpm -i ${dir}/pptpd-1.4.0-1.el6.x86_64.rpm

# set conf files
cp ${dir}/conf/pptpd.conf /etc/pptpd.conf
chown root:root /etc/pptpd.conf
#echo "localip 192.168.240.1" >> /etc/pptpd.conf
#echo "remoteip 192.168.240.2-100" >> /etc/pptpd.conf

cp ${dir}/conf/options.pptpd /etc/ppp/options.pptpd
chown root:root /etc/ppp/options.pptpd
#echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
#echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

cp ${dir}/conf/chap-secrets /etc/ppp/chap-secrets
chown root:root /etc/ppp/chap-secrets
chmod 600 /etc/ppp/chap-secrets

sed -i 's/^net.ipv4.ip_forward = 0$/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p

# iptables rules
iptables -A FORWARD -s 192.168.240.0/24 -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
service iptables save

# start services
chkconfig iptables on
service iptables start

chkconfig pptpd on
service pptpd start
