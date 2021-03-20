#!/bin/bash


install_reverse_proxy() {
    sudo apt-get update
    sudo apt install -yes apache2 python3-pip python3-openssl python3-pystache python3-requests python3-urllib3
    #sudo pip install htpasswd

    sudo mkdir /opt/reverse-proxy
    #sudo aws s3 cp s3://dimajix-training/scripts/aws/reverse-proxy /opt/reverse-proxy --recursive

    sudo python /opt/reverse-proxy/setup-reverse-proxy.py "$@"
    sudo /etc/init.d/httpd start
}


install_reverse_proxy "$@"
