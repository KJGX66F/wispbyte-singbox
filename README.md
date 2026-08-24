# WispByte Sing-Box VLESS + Cloudflare Tunnel 部署与使用指南

本指南专为 WispByte 等 PaaS 容器环境打造，详细说明如何部署基于 Sing-Box 与 Cloudflare 隧道的 VLESS 代理节点，以及如何在面板中获取和配置客户端链接。

---

## 📌 项目简介

本项目利用 Node.js 调度 Sing-Box 核心与 Cloudflare 临时隧道 (`cloudflared`)，实现双通道代理服务：
* **原生直连节点**：基于服务商分配的公网 IP 和映射端口传输。
* **Cloudflare 隧道节点**：自动分配 HTTPS/TLS 域名，流量经由 Cloudflare CDN 中转，提升跨国连接稳定性并突破网络限制。

---

## 🚀 WispByte 快速部署教程

### 第一步：准备项目文件
在 WispByte 控制台的 **Files（文件管理）** 页面中，确保根目录下包含以下核心配置文件：
1. `package.json`（定义项目依赖与启动脚本）
2. `config.json`（配置 Sing-Box 运行参数与 UUID）
3. `index.js`（项目主控制程序）

### 第二步：启动服务
1. 返回 WispByte 控制台首页 **Dashboard**。
2. 点击右侧或顶部的 **Restart（重启）** 按钮。
3. 系统将自动安装依赖包并启动 Sing-Box 与 Cloudflare 隧道。

### 第三步：获取运行日志与临时域名
1. 打开 **Console（控制台日志）** 窗口。
2. 观察输出日志，当看到以下提示时表示服务启动成功：
   * `[+] Web Server 已监听端口 xxxxx`
   * `[★] CF 临时隧道成功生成！`
3. 记录日志中打印出的隧道网址（格式为 `https://xxxx.trycloudflare.com`）。

---

## 🔗 节点链接获取与模板

项目启动后支持两种节点模式，请根据实际使用环境选择：

### 1. 原生直连节点模板（无 TLS）
适用于服务商 IP 连通性良好的环境。

* **语法模板**：
  ```text
  vless://{UUID}@{IP}:{PORT}?type=ws&security=none&path=%2Fapi%2Fv2%2Ftelemetry%2Fstream_8f91a#WispByte-VLESS
  ```

### 2. Cloudflare 临时隧道节点模板（开启 TLS）
推荐优先使用。流量经由 Cloudflare 加密中转，有效抵御 QoS 限速。

* **语法模板**：
  ```text
  vless://{UUID}@{CF_DOMAIN}:443?type=ws&security=tls&sni={CF_DOMAIN}&path=%2Fapi%2Fv2%2Ftelemetry%2Fstream_8f91a#WispByte-cf-VLESS
  ```

---

## 📋 关键参数对照说明表

在手动组装或修改节点时，请对照下表填写客户端参数：

| 参数占位符 | v2rayN / 客户端对应字段 | 说明 / 获取方式 |
| :--- | :--- | :--- |
| **`{UUID}`** | 用户 ID (id) | `config.json` 中配置的 UUID |
| **`{IP}`** | 地址 (Address) | 面板右侧 `SERVER INFO` 栏目的公网 IP |
| **`{PORT}`** | 端口 (Port) | 面板右侧 `SERVER INFO` 栏目的映射端口 |
| **`{CF_DOMAIN}`** | 地址 (Address) / Host / SNI | Console 日志中最新生成的 `xxxx.trycloudflare.com` 域名（**无需带 `https://`**） |
| **`{PATH}`** | 路径 (path) | `config.json` 与 `index.js` 中设定的 WebSocket 伪装路径（需 URL 编码，如 `%2Fapi%2Fv2%2Ftelemetry%2Fstream_8f91a`） |

---

## 📲 客户端导入与使用方法

### 方式一：剪贴板一键导入（推荐）
1. 根据上述模板组装好 `vless://` 开头的完整节点链接并复制。
2. 打开客户端（如 v2rayN、Shadowrocket 或 NekoBox）。
3. 选择 **从剪贴板导入批量 URL / 节点**。
4. 选中节点并进行真连接延迟测试。

### 方式二：手动在客户端中修改
若已有历史配置，仅需修改以下关键字段：
* **隧道节点**：需将 **地址 (Address)**、**Host** 以及 **SNI** 这三个字段同步修改为最新的 `xxxx.trycloudflare.com` 域名，端口保持为 **443**，传输层安全 (TLS) 设置为 **tls**。
* **直连节点**：**地址 (Address)** 填写服务器公网 IP，**端口 (Port)** 填写映射端口，传输层安全 (TLS) 设置为 **none**。

---

## ⚠️ 常见问题与排查指南

### Q1：为什么重启容器后临时隧道节点会变 `-1` 或超时？
* **原因**：Cloudflare Quick Tunnel (`trycloudflare.com`) 属于临时分配域名。**每次容器 Restart 或重新启动后，Cloudflare 都会分配一个新的随机域名**。
* **解法**：容器重启后，必须重新打开 Console 查看最新生成的 `https://xxxx.trycloudflare.com` 地址，并在客户端中更新 **地址、Host、SNI** 三项。

### Q2：客户端测试显示 `-1` 但直连端口正常？
1. 检查客户端中的 **SNI** 是否与 **地址 (Address)** 完全一致。
2. 确认路径 (Path) 是否包含开头的 `/`。
3. 在 v2rayN 等客户端中，尝试将节点配置中的 **Core 类型** 切换为 **sing-box** 或 **Xray**。

---

## 📄 许可证

MIT License
