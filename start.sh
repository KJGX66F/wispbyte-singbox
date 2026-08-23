#!/bin/bash

echo "================================="
echo " Wispbyte VLESS + Cloudflare Tunnel"
echo "================================="


PORT=16261

UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}


mkdir -p /home/container/bin

cd /home/container/bin



#################################
# 下载 sing-box
#################################

if [ ! -f sing-box ]; then

echo "[1/3] Download sing-box"


curl -L \
-o sing-box.tar.gz \
https://github.com/SagerNet/sing-box/releases/download/v1.12.0/sing-box-1.12.0-linux-amd64.tar.gz


tar -xzf sing-box.tar.gz


cp sing-box-*/sing-box ./sing-box


chmod +x sing-box


fi



#################################
# 下载 cloudflared
#################################

if [ ! -f cloudflared ]; then

echo "[2/3] Download cloudflared"


curl -L \
-o cloudflared \
https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64


chmod +x cloudflared


fi




#################################
# sing-box 配置
#################################


cat > config.json <<EOF
{
"log":{
"level":"info"
},

"inbounds":[
{
"type":"vless",

"listen":"127.0.0.1",

"listen_port":16261,


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




echo ""
echo "================================="
echo "UUID:"
echo "$UUID"
echo "================================="



#################################
# 启动 sing-box
#################################


./sing-box run -c config.json &


sleep 3



echo ""
echo "Starting Cloudflare Quick Tunnel..."
echo ""



#################################
# 启动CF并获取地址
#################################


./cloudflared tunnel \
--url http://127.0.0.1:16261 2>&1 | tee tunnel.log &



sleep 8



CF_URL=$(grep -o "https://[-a-zA-Z0-9]*\.trycloudflare\.com" tunnel.log | head -1)



if [ -z "$CF_URL" ]; then

echo "等待CF地址生成..."

sleep 10

CF_URL=$(grep -o "https://[-a-zA-Z0-9]*\.trycloudflare\.com" tunnel.log | head -1)

fi



HOST=$(echo $CF_URL | sed 's#https://##')



NODE="vless://${UUID}@${HOST}:443?encryption=none&security=tls&type=ws&host=${HOST}&path=%2Fws#Wispbyte-CF"



echo ""
echo "================================="
echo " Cloudflare Tunnel:"
echo "$CF_URL"
echo ""
echo " VLESS 节点:"
echo "$NODE"
echo "================================="



wait
