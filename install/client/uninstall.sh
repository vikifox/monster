#!/bin/bash
set -e
echo "####stop monster service####"
systemctl stop monster.service
work_dir=/var/opt/monster/client
rm -rf $work_dir
os=$(cat /proc/version)
if (echo $os|grep centos) || (echo $os|grep 'Red Hat')
then
    rm -rf /var/lib/systemd/system/monster.service
    rm -rf /etc/init.d/monster
    rm -rf /var/opt/monster/client
elif (echo $os|grep Ubuntu)
then
    rm -rf /etc/systemd/system/monster.service
    rm -rf /var/opt/monster/client
else
    echo "your os version is not supported!"
fi
echo "####admiset agent uninstall finished!####"
