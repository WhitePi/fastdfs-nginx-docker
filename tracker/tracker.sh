#!/bin/bash
#set -e

NGINX_START=${NGINX_START:-false}

function fdfs_set () {
    
    if [ -n "$PORT" ] ; then  
        sed -i "s|^port\s*=.*$|port = ${PORT}|g" /etc/fdfs/tracker.conf
    fi
    
    FASTDFS_LOG_FILE="${FASTDFS_BASE_PATH}/logs/trackerd.log"
    PID_NUMBER="${FASTDFS_BASE_PATH}/data/fdfs_trackerd.pid"
    
    if [ ! -f "$FASTDFS_LOG_FILE" ] ; then
        mkdir -p "${FASTDFS_BASE_PATH}/logs"
        touch "$FASTDFS_LOG_FILE"
    fi

    echo "try to start the tracker node..."
    # start the fastdfs node.	
    fdfs_trackerd /etc/fdfs/tracker.conf start
}

function nginx_set () {
    # start nginx.
    
    if [ "${NGINX_START}" = "false" ] || [ "${NGINX_START}" = "FALSE" ] ; then
        echo "nginx not start"
    else
        echo "try to start nginx"
        /usr/local/nginx/sbin/nginx
    fi
}

function health_check() {
    if [ $HOSTNAME = "localhost.localdomain" ]; then
        return 0
    fi
    # tracker OFFLINE, restart tracker.
    monitor_log=/tmp/monitor.log
    check_log=/tmp/health_check.log
    while true; do
        fdfs_monitor /etc/fdfs/client.conf 1>$monitor_log 2>&1
        cat $monitor_log|grep $HOSTNAME > $check_log 2>&1
        error_log=$(egrep "OFFLINE" "$check_log")
        if [ ! -z "$error_log" ]; then
            cat /dev/null > "$FASTDFS_LOG_FILE"
            fdfs_trackerd /etc/fdfs/tracker.conf stop
            fdfs_trackerd /etc/fdfs/tracker.conf start
        fi
        sleep 10
    done
}

fdfs_set $*
nginx_set $*
health_check &

# wait for pid file(important!),the max start time is 5 seconds,if the pid number does not appear in 5 seconds,start failed.
TIMES=5
while [ ! -f "$PID_NUMBER" -a $TIMES -gt 0 ]
do
    sleep 1s
    TIMES=`expr $TIMES - 1`
done

tail -f "$FASTDFS_LOG_FILE"
