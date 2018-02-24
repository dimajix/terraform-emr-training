#!/bin/bash

AWS_INFO_DIR="/mnt/var/lib/info/"

is_master() {
    grep -q "\"isMaster\": true" ${AWS_INFO_DIR}/instance.json
    return $?
}


install_reverse_proxy() {
    sudo yum install -y httpd24 mod24_proxy_html
    sudo pip install htpasswd

    sudo mkdir /opt/reverse-proxy
    sudo aws s3 cp s3://dimajix-training/scripts/aws/reverse-proxy /opt/reverse-proxy --recursive

    sudo python /opt/reverse-proxy/setup-reverse-proxy.py "$@"
    sudo /etc/init.d/httpd start
}


if is_master;
then
    install_reverse_proxy "$@"
fi

