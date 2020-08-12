### 开发环境
    centos 7.2(1511) django 1.11.16 python 2.7

### 服务端安装
    服务器操作系统版本要求 centos7.2及以上
    安装之前请关闭防火墙
```
git clone https://github.com/vikifox/monster.git
monster/install/server/auto_install.sh
```
说明：手动自定义安装请使用
monster/install/server/server_install.sh


### 客户端安装
    客户端脚本目前rhel/centos6、centos7,ubuntu16.04
    客户端python版本支持2.6.6及以上
    说明：为保证注册IP是管理IP（后续会被ansible等调用），客户端的IP抓取目前使用主机名解析，否则报错。
    如：主机名为bx-news-01 请在/etc/hosts中加入相应的解析 192.168.x.x bx-news-01，这样再执行monster_agent.py 可以保证正常运行。

step1: 修改文件install/client/monster_agent.py :
```
客户端正常使用需要修改脚本中的两个字段：
token = 'HPcWR7l4NJNJ'        #token是上传到服务器的密钥可以在WEB界面的系统配置中自定义
server_ip = '192.168.47.130'  #此项目为monster server的IP地址
```

step2: 拷贝install/client/ 目录到客户机的任意位置并执行:
```
cd client
/bin/bash install.sh
```
step3: 客户端管理
```
service monsterd start|stop|restart|status
```
注意：客户端全部功能需要配置服务器到客户端的ssh免密登录。


### 访问
    关闭防火墙或开通80端口
    http://your_server_ip
    自动安装的用户名root 密码monster123
    手动安装使用自定义创建的root用户名密码


