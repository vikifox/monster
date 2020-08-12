#!/bin/bash
set -e

# 初始化环境目录
main_dir="/var/opt/monster"
monster_dir="$main_dir/main"
data_dir="$main_dir/data"
config_dir="$main_dir/config"
logs_dir="$main_dir/logs"
cd "$( dirname "$0"  )"
cd .. && cd ..
cur_dir=$(pwd)
mkdir -p $monster_dir
mkdir -p $data_dir/scripts
mkdir -p $data_dir/files
mkdir -p $data_dir/ansible/playbook
mkdir -p $data_dir/ansible/roles
mkdir -p $config_dir
mkdir -p $config_dir/webssh
mkdir -p $logs_dir
mkdir -p $logs_dir/execlog
mkdir -p $main_dir/pid

# 关闭selinux
se_status=$(getenforce)
if [ $se_status != Enforcing ]
then
    echo "selinux is diabled, install progress is running"
    sleep 1
else
    echo "Please attention, Your system selinux is enforcing"
    read -p "Do you want to disabled selinux?[yes/no]": shut
    case $shut in
        yes|y|Y|YES)
            setenforce 0
            sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
            ;;
        no|n|N|NO)
            echo "please manual enable nginx access localhost 8000 port"
            echo "if not, when you open monster web you will receive a 502 error!"
            sleep 3
            ;;
        *)
            exit 1
            ;;
    esac
fi


# 安装依赖
echo "####install depandencies####"
read -p "do you want to use an internet yum repository?[yes/no]:" yum1
if [ ! $yum1 ]
then
yum1=yes
fi
case $yum1 in
	yes|y|Y|YES)
	    yum install -y epel-release
		yum install -y gcc expect python-pip python-devel ansible smartmontools dmidecode libselinux-python git rsync dos2unix openldap-devel
		;;
	no|n|N|NO)
        yum install -y gcc python-pip expect python-devel ansible smartmontools dmidecode libselinux-python git rsync dos2unix openldap-devel
		;;
	*)
		exit 1
		;;
esac

# 分发代码
if [ ! $cur_dir ] || [ ! $monster_dir ]
then
    echo "install directory info error, please check your system environment program exit"
    exit 1
else
    rsync --delete --progress -ra --exclude '.git' $cur_dir/ $monster_dir
fi
scp $monster_dir/install/server/ansible/ansible.cfg /etc/ansible/ansible.cfg

# install webssh
echo "build webssh"
cd $monster_dir/vendor/webssh/
/usr/bin/env python setup.py install
scp /var/opt/monster/main/install/server/webssh/webssh.service /usr/lib/systemd/system/webssh.service
/bin/systemctl enable webssh.service


#安装数据库
echo "####install database####"
read -p "do you want to create a new mysql database?[yes/no]:" db1
if [ ! $db1 ]
then
db1=yes
fi
case $db1 in
	yes|y|Y|YES)  
		echo "installing a new mariadb...."
		yum install -y mariadb-server mariadb-devel
		systemctl start mariadb.service
		chkconfig mariadb on
		mysql -e "CREATE DATABASE if not exists monster DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
		;;
	no|n|N|NO)
		read -p "your database ip address:" db_ip
		read -p "your database port:" db_port
		read -p "your database user:" db_user
		read -p "your database password:" db_password
		[ ! $db_password ] && echo "your db_password is empty confirm please press Enter key"
		[ -f /usr/bin/mysql ]
		sleep 3
		if [ $? -eq 0 ]
		then
			mysql -h$db_ip -P$db_port -u$db_user -p$db_password -e "CREATE DATABASE if not exists monster DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
		else
			yum install -y mysql
			mysql -h$db_ip -P$db_port -u$db_user -p$db_password -e "CREATE DATABASE if not exists monster DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
		fi
		sed -i "s/host = 127.0.0.1/host = $db_ip/g" $monster_dir/monster.conf
		sed -i "s/user = root/user = $db_user/g" $monster_dir/monster.conf
		sed -i "s/port = 3306/port = $db_port/g" $monster_dir/monster.conf
		sed -i "s/password =/password = $db_password/g" $monster_dir/monster.conf
		;;
	*) 
		exit 1                    
		;;
esac

# 安装mongodb
echo "####install mongodb####"
read -p "do you want to create a new Mongodb?[yes/no]:" mongo
if [ ! $mongo ]
then
mongo=yes
fi
case $mongo in
	yes|y|Y|YES)
		echo "installing a new Mongodb...."
		yum install -y mongodb mongodb-server
		/bin/systemctl start mongod 
		/bin/systemctl enable mongod 
		;;
	no|n|N|NO)
		read -p "your Mongodb ip address:" mongodb_ip
		read -p "your Mongodb port:" mongodb_port
		read -p "your Mongodb user:" mongodb_user
		read -p "your Mongodb password:" mongodb_pwd
		read -p "your Mongodb collection:" mongodb_collection
		[ ! $mongo_password ] && echo "your db_password is empty confirm please press Enter key"
		sleep 3
		sed -i "s/mongodb_ip = 127.0.0.1/host = $mongo_ip/g" $monster_dir/monster.conf
		sed -i "s/mongodb_user =/mongodb_user = $mongodb_user/g" $monster_dir/monster.conf
		sed -i "s/mongodb_port = 27017/port = $mongodb_port/g" $monster_dir/monster.conf
		sed -i "s/mongodb_pwd =/mongodb_pwd = $mongodb_pwd/g" $monster_dir/monster.conf
		sed -i "s/collection = sys_info/collection = $mongodb_collection/g" $monster_dir/monster.conf
		;;
	*)
		exit 1
		;;
esac

# 安装主程序
echo "####install monster####"
mkdir -p  ~/.pip
cat <<EOF > ~/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF
pip install --ignore-installed enum34==1.1.6
pip install --ignore-installed ipaddress==1.0.18
pip install kombu==4.2.1
pip install celery==4.2.1
pip install billiard==3.5.0.3
pip install pytz==2017.3
cd $monster_dir/vendor/django-celery-results-master
python setup.py build
python setup.py install

cd $monster_dir
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
echo "please create your monster' super admin:"
python manage.py createsuperuser
scp $monster_dir/install/server/monster.service /usr/lib/systemd/system
systemctl daemon-reload
chkconfig monster on
systemctl start monster.service

#安装redis
echo "####install redis####"
yum install redis -y
chkconfig redis on
systemctl start redis.service

# 安装celery
echo "####install celery####"
mkdir -p $config_dir/celery
scp $monster_dir/install/server/celery/beat.conf $config_dir/celery/beat.conf
scp $monster_dir/install/server/celery/celery.service /usr/lib/systemd/system
scp $monster_dir/install/server/celery/start_celery.sh $config_dir/celery/start_celery.sh
scp $monster_dir/install/server/celery/beat.service /usr/lib/systemd/system
chmod +x $config_dir/celery/start_celery.sh
systemctl daemon-reload
chkconfig celery on
chkconfig beat on
systemctl start celery.service
systemctl start beat.service

# 安装nginx
echo "####install nginx####"
yum install nginx -y
chkconfig nginx on
scp $monster_dir/install/server/nginx/monster.conf /etc/nginx/conf.d
scp $monster_dir/install/server/nginx/nginx.conf /etc/nginx
systemctl start nginx.service
nginx -s reload

# create ssh config
echo "create ssh-key, you could choose no if you had have ssh key"
if [ ! -e ~/.ssh/id_rsa.pub ]
then
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
else
    echo "you had already have a ssh rsa file."
fi
scp $monster_dir/install/server/ssh/config ~/.ssh/config


# 完成安装
echo "##############install finished###################"
systemctl daemon-reload
systemctl restart redis.service
systemctl restart mariadb.service
systemctl restart monster.service
systemctl restart celery.service
systemctl restart beat.service
systemctl restart mongod.service
systemctl restart sshd.service
systemctl restart webssh.service
echo "please access website http://server_ip"
echo "you have installed monster successfully!!!"
echo "################################################"
