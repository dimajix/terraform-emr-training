#!/usr/bin/env bash
#
# Script to setup a Kafka server

AWS_INFO_DIR="/mnt/var/lib/info/"

az="aws"
broker_id="0"

repo="https://downloads.apache.org/kafka"
scala_version="2.11"
kafka_version="2.4.1"
num_partitions="16"
repl_factor="1"
log_retention="168"
zookeeper_connect="localhost:2181"
mount_point="/mnt"


is_master() {
    grep -q "\"isMaster\": true" ${AWS_INFO_DIR}/instance.json
    return $?
}


install_kafka() {
    # Add Kafka user
    sudo useradd kafka

    # add directories that support kafka
    sudo mkdir -p /var/run/kafka
    sudo mkdir -p /var/log/kafka
    sudo mkdir -p ${mount_point}/kafka-logs

    # download kafka
    base_name=kafka_${scala_version}-${kafka_version}
    cd /tmp
    sudo curl -O ${repo}/${kafka_version}/$base_name.tgz

    # unpack the tarball
    sudo rm -rf /opt/kafka*
    sudo tar xzf /tmp/$base_name.tgz -C /opt
    sudo rm -f /tmp/$base_name.tgz

    sudo ln -sf /opt/kafka_${scala_version}-${kafka_version} /opt/kafka
}

configure_kafka() {
    cd /opt/kafka

    # configure the server
    cat config/server.properties \
        | sed "s|broker.id=0|broker.id=${broker_id}|" \
        | sed "s|log.dirs=/tmp/kafka-logs|log.dirs=${mount_point}/kafka-logs|" \
        | sed "s|num.partitions=1|num.partitions=${num_partitions}|" \
        | sed "s|log.retention.hours=168|log.retention.hours=${log_retention}|" \
        | sed "s|zookeeper.connect=localhost:2181|zookeeper.connect=${zookeeper_connect}|" \
        > /tmp/server.properties
    echo >> /tmp/server.properties
    echo "# rack ID" >> /tmp/server.properties
    echo "broker.rack=$az" >> /tmp/server.properties
    echo " " >> /tmp/server.properties
    echo "# replication factor" >> /tmp/server.properties
    echo "default.replication.factor=${repl_factor}" >> /tmp/server.properties
    echo "# enable topic delete" >> /tmp/server.properties
    echo "delete.topic.enable=true" >> /tmp/server.properties

    sudo mv -f /tmp/server.properties config/server.properties

    sudo chown -R kafka:kafka /opt/kafka
    sudo chown kafka:kafka /var/run/kafka
    sudo chown kafka:kafka /var/log/kafka
    sudo chown kafka:kafka ${mount_point}/kafka-logs
}


install_startup() {
    sudo tee /etc/init.d/kafka > /dev/null <<EOL
#!/bin/sh
# /etc/init.d/kafka: start the kafka daemon.

# chkconfig: - 80 20
# description: kafka

KAFKA_HOME=/opt/kafka
KAFKA_USER=kafka
KAFKA_SCRIPT=\$KAFKA_HOME/bin/kafka-server-start.sh
KAFKA_CONFIG=\$KAFKA_HOME/config/server.properties
KAFKA_CONSOLE_LOG=/var/log/kafka/kafkaServer.out

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

prog=kafka
DESC="kafka daemon"

RETVAL=0
STARTUP_WAIT=30
SHUTDOWN_WAIT=30

KAFKA_PIDFILE=\$KAFKA_HOME/run/kafka.pid


# Source function library.
. /etc/init.d/functions

start() {
  echo -n \$"Starting \$prog: "

        # Create pid file
        if [ -f \$KAFKA_PIDFILE ]; then
                read ppid < \$KAFKA_PIDFILE
                if [ \`ps --pid \$ppid 2> /dev/null | grep -c \$ppid 2> /dev/null\` -eq '1' ]; then
                        echo -n "\$prog is already running"
                        failure
                        echo
                        return 1
                else
                      rm -f \$KAFKA_PIDFILE
                fi
        fi

        rm -f \$KAFKA_CONSOLE_LOG
        mkdir -p \$(dirname \$KAFKA_PIDFILE)
        chown \$KAFKA_USER \$(dirname \$KAFKA_PIDFILE) || true
  
        # Run daemon
        mkdir -p \$(dirname \$KAFKA_CONSOLE_LOG)
        KAFKA_GC_LOG_OPTS=" " nohup sh \$KAFKA_SCRIPT \$KAFKA_CONFIG 2>&1 >> \$KAFKA_CONSOLE_LOG 2>&1 &
        PID=\$!
        echo \$PID > \$KAFKA_PIDFILE

        sleep 10
        if [ \`ps --pid \$PID 2> /dev/null | grep -c \$PID 2> /dev/null\` -eq '1' ]; then
                success
                echo
        else
                rm -f \$KAFKA_PIDFILE
                failure
                echo
                return 1
        fi
        return 0
}


stop() {
        echo -n \$"Stopping \$prog: "
        count=0;

        if [ -f \$KAFKA_PIDFILE ]; then
                read kpid < \$KAFKA_PIDFILE
                let kwait=\$SHUTDOWN_WAIT

                # Try issuing SIGTERM
                kill -15 \$kpid
                until [ \`ps --pid \$kpid 2> /dev/null | grep -c \$kpid 2> /dev/null\` -eq '0' ] || [ \$count -gt \$kwait ]
                        do
                        sleep 1
                        let count=\$count+1;
                done

                if [ \$count -gt \$kwait ]; then
                        kill -9 \$kpid
                fi
        fi

        rm -f \$KAFKA_PIDFILE
        rm -f \$KAFKA_CONSOLE_LOG
        success
        echo
}

reload() {
        stop
        start
}

restart() {
        stop
        start
}

status() {
        if [ -f \$KAFKA_PIDFILE ]; then
                read ppid < \$KAFKA_PIDFILE
                if [ \`ps --pid $ppid 2> /dev/null | grep -c \$ppid 2> /dev/null\` -eq '1' ]; then
                        echo "\$prog is running (pid \$ppid)"
                        return 0
                else
                      echo "\$prog dead but pid file exists"
                        return 1
                fi
        fi
        echo "\$prog is not running"
        return 3
}

case "\$1" in
start)
        start
        ;;

stop)
        stop
        ;;

reload)
        reload
        ;;

restart)
        restart
        ;;

status)
        status
        ;;
*)

echo \$"Usage: \$0 {start|stop|reload|restart|status}"
exit 1
esac
  
exit \$?
EOL

    sudo chmod a+rx /etc/init.d/kafka
}


if is_master;
then
    install_kafka
    configure_kafka
    install_startup

    # Start Kafka
    #sudo /etc/init.d/kafka start
fi

