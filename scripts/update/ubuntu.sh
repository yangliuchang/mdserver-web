#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8


wget -O /tmp/master.zip https://codeload.github.com/midoks/mdserver-web/zip/master
rm -rf /tmp/mdserver-web-master
cd /tmp && unzip  /tmp/master.zip
cp -rf /tmp/mdserver-web-master/* /www/server/mdserver-web
rm -rf /tmp/master.zip
rm -rf /tmp/mdserver-web-master


cd /www/server/mdserver-web/scripts && bash lib.sh
chmod 755 /www/server/mdserver-web/data


if [ ! -f /usr/local/bin/pip3 ];then
    python3 -m pip install --upgrade pip setuptools wheel -i https://mirrors.aliyun.com/pypi/simple
fi

cd /www/server/mdserver-web && pip3 install -r /www/server/mdserver-web/requirements.txt

pip3 install gunicorn==20.1.0
pip3 install gevent==21.1.2
pip3 install gevent-websocket==0.10.1
pip3 install requests==2.20.0
pip3 install flask-caching==1.10.1
pip3 install flask-socketio==5.2.0
pip3 install flask-session==0.3.2
pip3 install pymongo
pip3 install psutil

#venv
if [ ! -f /www/server/mdserver-web/bin/activate ];then
    cd /www/server/mdserver-web && python3 -m venv .
fi

if [ -f /www/server/mdserver-web/bin/activate ];then
    pip install --upgrade pip
    pip install --upgrade setuptools
    cd /www/server/mdserver-web && source /www/server/mdserver-web/bin/activate && pip3 install -r /www/server/mdserver-web/requirements.txt
else
    cd /www/server/mdserver-web && pip3 install -r /www/server/mdserver-web/requirements.txt
fi


if [ -f /etc/init.d/mw ];then 
    sh /etc/init.d/mw stop && rm -rf  /www/server/mdserver-web/scripts/init.d/mw && rm -rf  /etc/init.d/mw
fi

echo -e "stop mw"
isStart=`ps -ef|grep 'gunicorn -c setting.py app:app' |grep -v grep|awk '{print $2}'`
port=7200

if [ -f /www/server/mdserver-web/data/port.pl ];then
    port=$(cat /www/server/mdserver-web/data/port.pl)
fi
n=0
while [[ "$isStart" != "" ]];
do
    echo -e ".\c"
    sleep 0.5
    isStart=$(lsof -n -P -i:$port|grep LISTEN|grep -v grep|awk '{print $2}'|xargs)
    let n+=1
    if [ $n -gt 15 ];then
        break;
    fi
done


echo -e "start mw"
cd /www/server/mdserver-web && sh cli.sh start
isStart=`ps -ef|grep 'gunicorn -c setting.py app:app' |grep -v grep|awk '{print $2}'`
n=0
while [[ ! -f /etc/init.d/mw ]];
do
    echo -e ".\c"
    sleep 0.5
    let n+=1
    if [ $n -gt 15 ];then
        break;
    fi
done
echo -e "start mw success"

systemctl daemon-reload
/etc/init.d/mw default


