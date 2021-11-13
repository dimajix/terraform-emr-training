#!/bin/bash
basedir=$(dirname $0)


install_reverse_proxy() {
    sudo apt-get update
    sudo apt install --yes apache2 python3-pip python3-openssl python3-requests python3-urllib3
    sudo pip3 install htpasswd pystache

    sudo python3 $basedir/setup-reverse-proxy.py "$@"
    sudo a2enmod ssl headers request remoteip rewrite proxy proxy_html proxy_http proxy_wstunnel xml2enc
    sudo systemctl restart apache2
}


install_reverse_proxy "$@"

