#!/bin/bash

echo "================================="
echo " Wispbyte Sing-box VLESS WS"
echo "================================="


# =========================
# 参数
# =========================

PORT=16261

UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}

PATH_WS="/ws"


echo ""
echo "PORT: $PORT"
echo "UUID: $UUID"
echo ""


# =========================
# 安装依赖
# =========================

apt update -y >/dev/null 2>&1

apt install -y wget curl unzip jq >/dev/null 2>&1



# =========================
# 下载 sing-box
# =========================


if [ ! -f "./sing-box" ]; then

echo "Downloading sing-box..."

wget -q https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-amd64.tar.gz

tar -xzf sing-box-linux-amd64.tar.gz

mv sing-box-*/sing-box ./sing-box

chmod +x ./sing-box

rm -rf sing-box-linux-amd64.tar.gz sing-box-*

fi



# =========================
# 创建配置
# =========================


cat > config.json <<EOF
{
  "log": {
    "level": "info"
  },

  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",

      "listen": "::",
      "listen_port": $PORT,

      "users": [
        {
          "uuid": "$UUID"
        }
      ],

      "transport": {
        "type": "ws",
        "path": "$PATH_WS"
      }
    }
  ],


  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF



# =========================
# 启动 sing-box
# =========================


echo ""
echo "Starting sing-box..."

./sing-box run -c config.json &

sleep 3



# =========================
# Cloudflare Tunnel
# =========================


if [ ! -f "./cloudflared" ]; then

echo "Downloading cloudflared..."

wget -q \
https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
-O cloudflared

chmod +x cloudflared

fi



echo ""
echo "Starting Cloudflare Tunnel..."

rm -f tunnel.log


./cloudflared tunnel \
--url http://127.0.0.1:$PORT \
--no-autoupdate \
2>&1 | tee tunnel.log &



sleep 10



# =========================
# 获取CF地址
# =========================


CF_HOST=""

for i in {1..20}
do

CF_HOST=$(grep -o "https://[-a-zA-Z0-9]*\.trycloudflare\.com" tunnel.log | head -1)

if [ ! -z "$CF_HOST" ]; then
break
fi

sleep 2

done



if [ -z "$CF_HOST" ]; then

echo "Cloudflare Tunnel failed"

exit 1

fi



HOST=$(echo $CF_HOST | sed 's#https://##')



# =========================
# 输出节点
# =========================


NODE="vless://${UUID}@${HOST}:443?encryption=none&security=tls&type=ws&host=${HOST}&path=%2Fws#Wispbyte-CF"



echo ""
echo "================================="
echo " Cloudflare Tunnel:"
echo "$CF_HOST"
echo ""
echo " VLESS 节点:"
echo "$NODE"
echo "================================="


echo ""
echo "Keep alive..."



# 防止Wispbyte停止

tail -f /dev/null
