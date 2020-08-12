#!/bin/bash
set -e
main_dir="/var/opt/monster"
monster_dir="$main_dir/main"
data_dir="$main_dir/data"
config_dir="$main_dir/config"
logs_dir="$main_dir/logs"
cd "$( dirname "$0"  )"
cd .. && cd ..
cur_dir=$(pwd)
rsync --progress -ra --delete --exclude '.git' $cur_dir/ $monster_dir
#scp $monster_dir/install/server/ansible/ansible.cfg /etc/ansible/ansible.cfg
cd $monster_dir
pip install -r requirements.txt

#sql make migrations
if [ $1 ]
then
    python manage.py makemigrations
    for app in $*
    do
        python manage.py migrate $app
    done
else
    python manage.py makemigrations
    python manage.py migrate
fi
echo "####update celery####"
mkdir -p $config_dir/celery
scp $monster_dir/install/server/celery/beat.conf $config_dir/celery/beat.conf
scp $monster_dir/install/server/celery/celery.service /usr/lib/systemd/system
scp $monster_dir/install/server/celery/start_celery.sh $config_dir/celery/start_celery.sh
scp $monster_dir/install/server/celery/beat.service /usr/lib/systemd/system
chmod +x $config_dir/celery/start_celery.sh
scp $monster_dir/install/server/nginx/monster.conf /etc/nginx/conf.d
scp $monster_dir/install/server/nginx/nginx.conf /etc/nginx
scp $monster_dir/install/server/nginx/monster.conf /etc/nginx/conf.d
scp $monster_dir/install/server/webssh/webssh.service /usr/lib/systemd/system
nginx -s reload
echo "##############install finished###################"
systemctl daemon-reload
nginx -s reload
service monster restart
service celery restart
echo "you have updated monster successfully!!!"
echo "################################################"
