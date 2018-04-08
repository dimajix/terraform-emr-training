#!/bin/bash

AWS_INFO_DIR="/mnt/var/lib/info/"


is_master() {
    grep -q "\"isMaster\": true" ${AWS_INFO_DIR}/instance.json
    return $?
}


exec_mysql() {
    mysql --user=root -e "$@"
}


install_training_repo() {
    sudo yum -y install git python27-boto3

    git clone https://github.com/dimajix/spark-training.git /home/hadoop/spark-training
    chown hadoop:hadoop /home/hadoop/spark-training

    # Copy Zeppelin Notebooks into Zeppelin
    #srcdir=/home/hadoop/spark-training
    #tgtdir=/var/lib/zeppelin
    #files=$(find $srcdir -type d -name "zeppelin-*")

    #for file in $files; do
    #    reldir=${file#$srcdir/}
    #    src=$file
    #    dst=$tgtdir/$reldir
    #    mkdir -p $(dirname $dst)
    #    echo $src "=>" $dst
    #    cp -a $src $dst
    #done
}


create_mysql_database() {
    sudo yum -y install mysql-server
    sudo /etc/init.d/mysqld start

    exec_mysql "CREATE DATABASE training;"
    exec_mysql "GRANT ALL ON TABLE training.* TO 'user'@'%' IDENTIFIED BY 'user'; FLUSH PRIVILEGES;"
    exec_mysql "GRANT ALL ON TABLE training.* TO 'user'@'localhost' IDENTIFIED BY 'user'; FLUSH PRIVILEGES;"
}



if is_master;
then
    install_training_repo
    create_mysql_database
fi

