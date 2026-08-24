const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const { spawn, exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.SERVER_PORT || process.env.PORT || 3000;
const WS_PATH = '/api/v2/telemetry/stream_8f91a';
const LOCAL_PORT = 10086;

const sbPath = path.join(__dirname, 'sing-box');
const cfPath = path.join(__dirname, 'cloudflared');

const SB_URL = "[https://ghproxy.net/https://github.com/SagerNet/sing-box/releases/download/v1.10.7/sing-box-1.10.7-linux-amd64.tar.gz](https://ghproxy.net/https://github.com/SagerNet/sing-box/releases/download/v1.10.7/sing-box-1.10.7-linux-amd64.tar.gz)";
const CF_URL = "[https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64)";

// 启动 sing-box 内核
function startSingBox() {
  if (fs.existsSync(sbPath)) {
    try { fs.chmodSync(sbPath, '755'); } catch (e) {}
    console.log('[+] 正在启动 sing-box 内核...');
    spawn(sbPath, ['run', '-c', 'config.json']);
  }
}

// 启动 Cloudflare 临时隧道
function startCloudflareTunnel() {
  if (fs.existsSync(cfPath)) {
    try { fs.chmodSync(cfPath, '755'); } catch (e) {}
    console.log('[+] 正在启动 Cloudflare 临时隧道...');
    const cf = spawn(cfPath, ['tunnel', '--url', `[http://127.0.0.1](http://127.0.0.1):${PORT}`]);

    cf.stderr.on('data', (data) => {
      const msg = data.toString();
      const match = msg.match(/https:\/\/[a-zA-Z0-9-]+\.trycloudflare\.com/);
      if (match) {
        console.log('\\n==================================================');
        console.log(`[★] CF 临时隧道成功生成！`);
        console.log(`[★] 隧道地址: ${match[0]}`);
        console.log('==================================================\\n');
      }
    });
  }
}

// 环境检测与二进制自动下载
if (!fs.existsSync(sbPath)) {
  exec(`curl -Ls "${SB_URL}" -o sb.tar.gz && tar -xvf sb.tar.gz && cp sing-box-*/sing-box ./sing-box && rm -rf sing-box-* sb.tar.gz`, () => startSingBox());
} else {
  startSingBox();
}

if (!fs.existsSync(cfPath)) {
  exec(`curl -Ls "${CF_URL}" -o cloudflared && chmod +x cloudflared`, () => startCloudflareTunnel());
} else {
  startCloudflareTunnel();
}

// WebSocket 节点协议转发
const wsProxy = createProxyMiddleware({
  target: `[http://127.0.0.1](http://127.0.0.1):${LOCAL_PORT}`,
  ws: true,
  changeOrigin: true,
  logLevel: 'silent'
});
app.use(WS_PATH, wsProxy);

app.get('/', (req, res) => res.status(200).send('Server Operational'));

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`[+] Web Server 已监听端口 ${PORT}`);
});

server.on('upgrade', (req, socket, head) => {
  if (req.url.startsWith(WS_PATH)) {
    wsProxy.upgrade(req, socket, head);
  } else {
    socket.destroy();
  }
});

// 定时自调心跳，防止容器休眠（每2分钟一次）
setInterval(() => {
  require('http').get(`[http://127.0.0.1](http://127.0.0.1):${PORT}/`, () => {}).on('error', () => {});
}, 120000);
