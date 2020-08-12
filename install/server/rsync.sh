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
rsync --progress -ra --exclude '.git' $cur_dir/ $monster_dir
/bin/systemctl restart  monster.service
/bin/systemctl restart  celery.service
