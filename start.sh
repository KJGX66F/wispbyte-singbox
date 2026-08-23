#!/bin/bash

set -e

PORT=${PORT:-16261}

UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}

echo "=============================="
echo "Wispbyte Sing-box"
echo "PORT: $PORT"
echo "UUID: $UUID"
echo "=============================="


ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
DOWNLOAD="https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-amd64.tar.gz"
else
DOWNLOAD="https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-arm64.tar.gz"
fi


if [ ! -f sing-box ]; then

echo "Downloading sing-box..."

wget -q $DOWNLOAD -O singbox.tar.gz

tar -xzf singbox.tar.gz

mv sing-box-*/* .

chmod +x sing-box

fi


cat > config.json <<EOF
{
  "log": {
    "level": "info"
  },

  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-ws",
      "listen": "::",
      "listen_port": $PORT,

      "users": [
        {
          "uuid": "$UUID"
        }
      ],

      "transport": {
        "type": "ws",
        "path": "/ws"
      }
    }
  ],

  "outbounds": [
    {
      "type": "direct"
    }
  ]
}
EOF


echo ""
echo "=============================="
echo "VLESS WS START"
echo "PORT=$PORT"
echo "UUID=$UUID"
echo "PATH=/ws"
echo "=============================="
echo ""


./sing-box run -c config.json
