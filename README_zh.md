# 华为 UniVPN 客户端 Docker 容器 (带 VNC/SOCKS/HTTP 代理访问)

[English Version](README.md)

[![Docker Hub](https://img.shields.io/docker/pulls/triatk/univpn.svg)](https://hub.docker.com/r/triatk/univpn)
[![Docker Image Size](https://img.shields.io/docker/image-size/triatk/univpn/latest)](https://hub.docker.com/r/triatk/univpn)

本项目提供了一个用于华为 UniVPN 图形界面客户端 (版本 **10781.21.0.0831**) 的 Docker 容器，可通过 VNC 或 Web 浏览器 (noVNC) 访问。它还包含 SOCKS5 和 HTTP 代理，允许宿主机应用程序通过容器的 VPN 连接路由流量。

**本版本新增功能：** 容器包含智能**保活系统 (Keep-Alive)**，如果连接断开或应用程序崩溃，它可以自动重启 VPN 客户端。

**免责声明：** 本项目为非官方项目，与华为公司无任何关联。华为 UniVPN 客户端软件本身为华为公司的专有财产。尽管为了方便构建，二进制文件已包含在 `./bin` 目录中，但**您有责任在使用时遵守华为的服务条款和许可协议**。

## 内含软件信息 (版本: 10781.21.0.0831)

| 字段           | 值                                                           |
| :------------- | :----------------------------------------------------------- |
| Release 版本   | **10781.21.0.0831**                                          |
| 二进制文件位置 | 包含在仓库中: `./bin/univpn-linux-64-10781.21.0.0831.zip` (amd64)、`./bin/univpn-linuxarm-64-10781.21.0.0831.zip` (arm64) |
| 基础操作系统   | Ubuntu 22.04 LTS                                             |
| 支持架构       | `linux/amd64`、`linux/arm64`                                 |
| 访问方式       | VNC (端口 5901), Web 浏览器通过 noVNC (端口 6901)            |
| 代理           | SOCKS5 (Dante) 在端口 1080, **HTTP (Tinyproxy) 在端口 8888** |

## 主要特性

- **隔离的 GUI:** 在安全的 Docker 容器中运行华为 UniVPN。
- **远程访问:** 支持 VNC 客户端或 Web 浏览器 (noVNC)。
- **自动启动与保活 (Keep-Alive):** UniVPN 客户端自动启动。内置守护脚本会监控进程，若进程崩溃或网络连接丢失（自动重连），脚本会自动重启 VPN。
- **双重代理:**
  - **SOCKS5** (端口 `1080`): 通过 VPN 路由流量。
  - **HTTP** (端口 `8888`): 链式转发到 SOCKS5，允许 HTTP 应用使用 VPN。
- **易于配置:** 通过 Docker Compose 和 `.env` 文件管理。
- **必要权限:** 包含 `NET_ADMIN` 和 `TUN` 设备访问权限。

## 先决条件

- 宿主机已安装 Docker 和 Docker Compose。
- 宿主机已加载 `tun` 内核模块 (`sudo modprobe tun`)。

## 如何使用 (推荐 Docker Compose)

1.  **克隆仓库:**

    ```bash
    git clone https://github.com/zx900930/docker-univpn.git
    cd docker-univpn
    ```

2.  **创建 `.env` 文件:**
    在 `docker-univpn` 目录下创建一个名为 `.env` 的文件。复制以下内容并根据需要修改：

    ```dotenv
    # .env 文件

    # VPN账号设置 (只有使用CLI镜像时需要)
    VPN_USERNAME=your_username_here
    VPN_PASSWORD=your_password_here

    # 安全与网络设置
    VNC_PASSWORD=YourStrongVncPassword123
    SPOOF_MAC=00:1A:2B:3C:4D:5E

    # --- 自动重连 (Auto Reconnect) 设置 ---
    # 设置为 'true' 以启用网络断开时的自动重启
    AUTO_RECONNECT=true

    # 用于检测连接状态的目标 IP (例如 8.8.8.8 或公司内网网关)
    RECONNECT_PING_TARGET=8.8.8.8

    # 启动后等待登录的宽限期 (秒)，在此期间不进行 Ping 检测
    RECONNECT_GRACE_PERIOD=60

    # Dante SOCKS5 出口 VPN 网卡。
    # 请设置为当前环境中 UniVPN 创建的 VPN 网卡名，例如 ipsec_vnic。
    DANTE_INTERFACE=cnem_vnic
    ```

3.  **启动容器:**

    `docker-compose.yml` 在 `image:` 之外还加了 `build:` 配置，所以全程本地构建、本地运行，不会从 Docker Hub 拉取，也不会推送上去。

    ```bash
    docker-compose up -d            # 第一次会本地构建，之后直接运行
    docker-compose up -d --build    # 强制重新构建（比如改了 Dockerfile 之后）
    ```

4.  **连接到 GUI:**

    - **VNC 客户端:** 连接到 `localhost:5901` (密码: `VNC_PASSWORD`)。
    - **Web 浏览器:** 访问 `http://localhost:6901/vnc.html` (密码: `VNC_PASSWORD`)。

5.  **使用代理:**
    - **SOCKS5:** `localhost:1080`
    - **HTTP:** `localhost:8888`

    Dante 会等待 `DANTE_INTERFACE` 指定的网卡出现后再启动。默认值是 `cnem_vnic`；如果当前环境中 UniVPN 创建的是其他 VPN 网卡，例如 `ipsec_vnic`，请在 `.env` 中设置对应名称。
    VPN 连接成功后，可以在容器内查看实际网卡名：
    ```bash
    docker compose exec univpn ip -br link
    ```
    如果使用 CLI compose 文件，请运行：
    ```bash
    docker compose -f docker-compose-cli.yml exec univpn ip -br link
    ```

## 纯命令行 (CLI) Docker 镜像

本仓库还提供了一个 `Dockerfile.cli` 文件，用于构建 UniVPN 客户端的纯命令行 (CLI) 版本。此镜像适用于不需要图形界面的环境，例如 CI/CD 流水线、脚本编写、无头服务器，或 arm64 主机（见下方[已知问题](#已知问题)）。

**新的 Dockerfile:** `Dockerfile.cli`
**`docker-compose-cli.yml` 使用的镜像标签:** `triatk/univpn:latest-cli`

### 构建 CLI 镜像

已更新 CI 工作流程 (`.github/workflows/docker-image.yml`)，当推送到 `cli-only-image` 分支时，会自动构建并推送 `triatk/univpn` 镜像。

您也可以手动构建：

```bash
# 确保您的 bin/ 目录下有对应架构的 zip 文件
docker build -t triatk/univpn:latest-cli -f Dockerfile.cli .
```

### 创建连接配置

CLI 客户端 (`UniVPNCS`) 登录前需要一份已保存的连接配置。用 `UniVPNCS` 自带的文本菜单**一次性**创建即可——这个过程完全不经过 GUI，所以在 amd64 和 arm64 上行为完全一致：

```bash
docker run --rm -it \
  -v ./univpn_config:/home/vpnuser/UniVPN \
  --name univpn-setup \
  --user vpnuser -e HOME=/home/vpnuser \
  triatk/univpn:latest-cli \
  /usr/local/UniVPN/serviceclient/UniVPNCS
```

按菜单操作：

```
Welcome to UniVPN!
1:New Connection          <- 输入 1
2:Exit

Please choose Connection Type
1:SSL VPN                 <- 输入 1
2:L2TP/IPSec
3:Cancel

                       SSL Configuration
1:Connection Name(Required):   <- 输入 1，再输入连接名称
2:Description:
3:Gateway Address(Required):   <- 输入 3，再输入网关地址
4:Port:443                     <- 输入 4，再输入网关端口
5:Tunnel Mode:Auto-sensing
6:Certificate Authentication:Disable
7:GmSSL algorithm:Disable
8:Save                         <- 名称/网关/端口都填好后输入 8 保存
9:Cancel
```

保存后输入 `2` 退出。这一步会在宿主机的 `./univpn_config/` 下写入 `sysconfig.ini` 和 `config/<连接名>.ini`——这个目录已经在 `.gitignore` 里了，不要把它提交到版本控制，因为里面有你的真实网关地址。

### 使用 CLI 镜像

`./univpn_config/` 下有了配置文件之后，在 `.env` 里填好账号密码（参考 `.envexample`），正常启动容器即可。`docker-compose-cli.yml` 同样加了 `build:` 配置，本地构建，不会去 Docker Hub 拉取：

```bash
docker-compose -f docker-compose-cli.yml up -d            # 第一次会本地构建
docker-compose -f docker-compose-cli.yml up -d --build    # 强制重新构建
docker-compose -f docker-compose-cli.yml logs -f
```

`univpn-keeper.sh.cli` 会自动驱动 `UniVPNCS`：从菜单里选中第一个已保存的连接、发起连接，并用环境变量里的 `VPN_USERNAME`/`VPN_PASSWORD` 自动应答用户名密码提示。SOCKS5 (`1080`) 和 HTTP (`8888`) 代理跟 GUI 镜像一样会自动起来。

手动触发重连：

```bash
docker exec univpn reconnect
```

## 自动重连与手动重启

容器使用包装脚本 (`univpn-keeper.sh`) 来管理 VPN 应用程序。

### 自动重连逻辑

如果在 `.env` 文件中设置了 `AUTO_RECONNECT=true`:

1.  VPN 启动。
2.  脚本等待 `RECONNECT_GRACE_PERIOD` 秒（给您时间输入密码/2FA）。
3.  宽限期过后，脚本每 10 秒 Ping 一次 `RECONNECT_PING_TARGET`。
4.  如果 Ping 失败（网络超时），脚本会**强制结束 VPN 进程**。
5.  循环逻辑检测到进程退出，随即**自动启动一个新的 VPN 实例**。

### 手动重启

如果 VPN 卡死，或者您需要手动重启它而不想重启整个容器：

- **从宿主机终端 (GUI 镜像):**
  ```bash
  docker exec univpn-vnc reconnect
  ```
- **从宿主机终端 (CLI 镜像):**
  ```bash
  docker exec univpn reconnect
  ```
- **从 VNC 内部 (仅 GUI 镜像):**
  打开 Fluxbox 终端 (右键 -> Applications -> Shells -> Bash) 并输入:
  ```bash
  reconnect
  ```

## 容器内部

- GUI 镜像运行一个 `Xvfb` 虚拟 X server，用 `x11vnc` 提供 VNC 连接，上层再跑 Fluxbox 窗口管理器。
- **UniVPN GUI** 由 `/usr/local/bin/univpn-keeper.sh` 脚本启动。
- **Dante (SOCKS5)** 和 **Tinyproxy (HTTP)** 通过 Supervisor 在后台运行。

## 配置与持久化

- **环境变量:** 所有设置均通过 `.env` 文件控制。
- **持久化:** 要保存您的 VPN 配置文件和设置，请取消注释 `docker-compose.yml` 中的 volume 配置:
  ```yaml
  volumes:
    - ./univpn_config:/home/vpnuser/UniVPN
  ```

## 故障排除

- **无限重启循环:** 如果看到 VPN 反复打开和关闭，请检查 `RECONNECT_PING_TARGET` 是否可达。如果 VPN 禁止访问外网但允许访问内网，请将目标 IP 设置为内网服务器 IP。
- **登录时间不足:** 在 `.env` 文件中增加 `RECONNECT_GRACE_PERIOD` 的值。
- **容器崩溃:** 查看日志: `docker-compose logs univpn`。注意 `docker-compose logs` 只能看到 supervisor 自己的编排日志——VPN 客户端真正的日志在容器内的 `/var/log/supervisor/univpn-keeper_stdout.log`（GUI 镜像）或 `univpn-keeper_stdout.log`/`univpn-keeper_stderr.log`（CLI 镜像）。

## 已知问题

- **GUI 镜像在 `linux/arm64` 上：通过"New Connection"创建连接时，UniVPN 窗口可能崩溃（对话框里第一次点击/按键就黑屏）。** 这是 Qt5 的 XCB 键盘处理（`QXcbKeyboard::updateKeymap` → `xkb_keymap_unref` 传入了一个无效指针）在 `libxkbcommon` 内部的崩溃，无论用哪种 VNC 后端（TigerVNC 的 Xvnc，还是 Xvfb+x11vnc）都会复现——不是这个项目的 Dockerfile/配置能修复的问题。守护脚本会在几秒内自动重启崩溃的进程，但对话框里的输入会反复丢失。

  **规避方法：** 改用 CLI 客户端的文本菜单创建连接配置，见上方[创建连接配置](#创建连接配置)。这个流程完全不碰 Qt/X11，在任何架构上都不受此 bug 影响。`./univpn_config/` 下有了配置文件之后，GUI 主界面（选中已有连接点 **Connect**）是正常的，只有 **New Connection** 对话框受影响。

## 许可证

本仓库中的 Dockerfile 和脚本根据 [MIT 许可证](LICENSE) 提供。`./bin` 目录中的华为软件受其专有协议约束。
