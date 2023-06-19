#!/bin/bash

AWS_INFO_DIR="/mnt/var/lib/info/"


is_master() {
    grep -q "\"isMaster\": true" ${AWS_INFO_DIR}/instance.json
    return $?
}


install_training_repo() {
    sudo yum -y install git

    git clone https://github.com/dimajix/pyspark-datascience.git /home/hadoop/pyspark-datascience
    chown hadoop:hadoop /home/hadoop/pyspark-datascience
}



if is_master;
then
    install_training_repo
fi

