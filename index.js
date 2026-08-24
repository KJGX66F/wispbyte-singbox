const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const WS_PATH = '/api/v2/telemetry/stream_8f91a';
const LOCAL_PORT = 10086;
const sbPath = path.join(__dirname, 'sing-box');

// 如果服务器本地没有 sing-box，则自动下载解压
if (!fs.existsSync(sbPath)) {
  console.log('未检测到 sing-box，正在自动获取...');
  try {
    execSync('curl -Ls https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-1.11.0-beta.10-linux-amd64.tar.gz -o sb.tar.gz && tar -xvf sb.tar.gz && cp sing-box-*/sing-box ./sing-box && rm -rf sing-box-* sb.tar.gz');
    console.log('sing-box 下载完毕！');
  } catch (err) {
    console.error('下载失败:', err);
  }
}

// 启动 sing-box
if (fs.existsSync(sbPath)) {
  fs.chmodSync(sbPath, '755');
  const sb = spawn(sbPath, ['run', '-c', 'config.json']);
  sb.on('error', (err) => console.error('[sing-box Error]', err));
}

// 1. 代理 WebSocket 到 sing-box
const wsProxy = createProxyMiddleware({
  target: `http://127.0.0.1:${LOCAL_PORT}`,
  ws: true,
  changeOrigin: true,
  logLevel: 'silent'
});
app.use(WS_PATH, wsProxy);

// 2. 根目录伪装真实网站
app.use('/', createProxyMiddleware({
  target: 'https://www.bing.com',
  changeOrigin: true,
  followRedirects: true,
  logLevel: 'silent'
}));

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

server.on('upgrade', (req, socket, head) => {
  if (req.url.startsWith(WS_PATH)) {
    wsProxy.upgrade(req, socket, head);
  } else {
    socket.destroy();
  }
});
