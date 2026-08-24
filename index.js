const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const WS_PATH = '/api/v2/telemetry/stream_8f91a';
const LOCAL_PORT = 10086;

// 1. 启动本地预置的 sing-box 进程
const sbPath = path.join(__dirname, 'sing-box');
if (fs.existsSync(sbPath)) {
  // 赋予可执行权限并启动
  fs.chmodSync(sbPath, '755');
  const sb = spawn(sbPath, ['run', '-c', 'config.json']);
  sb.on('error', (err) => console.error('[Error]', err));
} else {
  console.error('[Error] 未在根目录找到 sing-box 二进制文件！');
}

// 2. 将节点 WS 流量转发至本地 sing-box 端口
const wsProxy = createProxyMiddleware({
  target: `http://127.0.0.1:${LOCAL_PORT}`,
  ws: true,
  changeOrigin: true,
  logLevel: 'silent'
});
app.use(WS_PATH, wsProxy);

// 3. 根路径反代真实网站（实现深度伪装）
app.use('/', createProxyMiddleware({
  target: 'https://www.bing.com',
  changeOrigin: true,
  followRedirects: true,
  logLevel: 'silent'
}));

const server = app.listen(PORT, () => {
  console.log(`Service started on port ${PORT}`);
});

// 处理 WebSocket 升级握手与路径过滤
server.on('upgrade', (req, socket, head) => {
  if (req.url.startsWith(WS_PATH)) {
    wsProxy.upgrade(req, socket, head);
  } else {
    socket.destroy();
  }
});
