#!/bin/bash

echo "=============================="
echo "Wispbyte Sing-box"
echo "=============================="

PORT=${PORT:-16261}
UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}

echo "PORT: $PORT"
echo "UUID: $UUID"

mkdir -p /home/container/sing-box

cd /home/container/sing-box

if [ ! -f sing-box ]; then

echo "Downloading sing-box..."

curl -L -o sing-box.tar.gz \
https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-amd64.tar.gz

tar -xzf sing-box.tar.gz

cp sing-box-*/sing-box ./sing-box

chmod +x sing-box

fi


cat > config.json <<EOF
{
"log":{
"level":"info"
},

"inbounds":[
{
"type":"vless",
"tag":"vless-in",
"listen":"0.0.0.0",
"listen_port":$PORT,

"users":[
{
"uuid":"$UUID"
}
],

"transport":{
"type":"ws",
"path":"/ws"
}
}
],

"outbounds":[
{
"type":"direct"
}
]
}
EOF


echo "=============================="
echo "VLESS WS READY"
echo "PORT: $PORT"
echo "UUID: $UUID"
echo "PATH: /ws"
echo "=============================="


./sing-box run -c config.json
