#!/bin/bash

AWS_INFO_DIR="/mnt/var/lib/info/"

is_master() {
    grep -q "\"isMaster\": true" ${AWS_INFO_DIR}/instance.json
    return $?
}


install_reverse_proxy() {
    sudo yum install -y httpd24 mod24_proxy_html mod24_ssl
    sudo pip install htpasswd urllib3 pystache requests pyOpenSSL

    sudo mkdir /opt/reverse-proxy
    sudo aws s3 cp s3://dimajix-training/scripts/aws/reverse-proxy /opt/reverse-proxy --recursive

    # Run the last step in background, since the Python script needs
    # YARN to be running. And YARN will be started after all bootstrap
    # actions have been executed
    sudo python /opt/reverse-proxy/setup-reverse-proxy.py "$@" && \
    sudo /etc/init.d/httpd start & disown
}


if is_master;
then
    install_reverse_proxy "$@"
fi

