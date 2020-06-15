#!/bin/bash
#set -e

NGINX_START=${NGINX_START:-true}

GROUP_NAME=${GROUP_NAME:-group1}
if [ -n "$GET_TRACKER_SERVER" ]; then
    export TRACKER_SERVER=$(eval $GET_TRACKER_SERVER)
fi

function fdfs_set () {
    
    if [ -n "$PORT" ] ; then  
        sed -i "s|^port\s*=.*$|port = ${PORT}|g" /etc/fdfs/storage.conf
        sed -i "s|^storage_server_port\s*=.*$|storage_server_port = ${PORT}|g" /etc/fdfs/mod_fastdfs.conf
    fi
    
    if [ -n "$TRACKER_SERVER" ] ; then  
        sed -i "s|tracker_server\s*=.*$|tracker_server = ${TRACKER_SERVER}|g" /etc/fdfs/storage.conf
        sed -i "s|tracker_server\s*=.*$|tracker_server = ${TRACKER_SERVER}|g" /etc/fdfs/client.conf
        sed -i "s|tracker_server\s*=.*$|tracker_server = ${TRACKER_SERVER}|g" /etc/fdfs/mod_fastdfs.conf
    fi
    
    sed -i "s|^group_name\s*=.*$|group_name = ${GROUP_NAME}|g" /etc/fdfs/storage.conf
    sed -i "s|^group_name\s*=.*$|group_name = ${GROUP_NAME}|g" /etc/fdfs/mod_fastdfs.conf
    sed -i "s|group_name|${GROUP_NAME}|g" /usr/local/nginx/conf/nginx.conf
    
    FASTDFS_LOG_FILE="${FASTDFS_BASE_PATH}/logs/storaged.log"
    PID_NUMBER="${FASTDFS_BASE_PATH}/data/fdfs_storaged.pid"
   
    if [ ! -f "$FASTDFS_LOG_FILE" ] ; then
        mkdir -p "${FASTDFS_BASE_PATH}/logs"
        touch "$FASTDFS_LOG_FILE"
    fi
 
    echo "try to start the storage node..."
    # start the fastdfs node.	
    fdfs_storaged /etc/fdfs/storage.conf start
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
    # Storage OFFLINE, restart storage.
    monitor_log=/tmp/monitor.log
    check_log=/tmp/health_check.log
    while true; do
        fdfs_monitor /etc/fdfs/client.conf 1>$monitor_log 2>&1
        cat $monitor_log|grep $HOSTNAME > $check_log 2>&1
        error_log=$(egrep "OFFLINE" "$check_log")
        if [ ! -z "$error_log" ]; then
            cat /dev/null > "$FASTDFS_LOG_FILE"
            fdfs_storaged /etc/fdfs/storage.conf stop
            fdfs_storaged /etc/fdfs/storage.conf start
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
