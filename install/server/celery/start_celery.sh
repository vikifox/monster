#!/bin/bash
/usr/bin/celery multi start w1 w2 -c 2 --app=monster --logfile="/var/opt/monster/logs/%n%I.log" --pidfile=/var/opt/monster/pid/%n.pid

