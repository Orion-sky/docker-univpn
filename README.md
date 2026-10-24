# Huawei UniVPN Client Docker Container with VNC/SOCKS/HTTP Proxy Access

[简体中文](README_zh.md)

[![Docker Hub](https://img.shields.io/docker/pulls/triatk/univpn.svg)](https://hub.docker.com/r/triatk/univpn) [![Docker Image Size](https://img.shields.io/docker/image-size/triatk/univpn/latest)](https://hub.docker.com/r/triatk/univpn)

This project provides a Docker container for the Huawei UniVPN GUI client (version **10781.21.0.0831**), accessible via VNC or a web browser (noVNC). It also includes a SOCKS5 proxy (Dante) and an HTTP proxy (Tinyproxy) to route traffic from host applications through the container's VPN connection.

**New in this version:** The container includes an intelligent **Keep-Alive system** that can automatically restart the VPN client if the connection drops or the application crashes.

**Disclaimer:** This project is unofficial and not affiliated with or endorsed by Huawei. The Huawei UniVPN client software itself is proprietary to Huawei. While the client binary is included in this repository's `./bin` directory for build convenience, **you are responsible for complying with Huawei's terms of service and licensing agreements** regarding its use. This container is provided for technical convenience, isolation, and remote access purposes only. The maintainers of this repository do not grant you any license to use the Huawei software.

## Included Software Information (Version: 10781.21.0.0831)

| Field           | Value                                                               |
| :-------------- | :------------------------------------------------------------------ |
| Release         | **10781.21.0.0831**                                                 |
| Binary Location | Included in repository: `./bin/univpn-linux-64-10781.21.0.0831.zip` (amd64), `./bin/univpn-linuxarm-64-10781.21.0.0831.zip` (arm64) |
| Base OS         | Ubuntu 22.04 LTS                                                    |
| Architectures   | `linux/amd64`, `linux/arm64`                                        |
| Access Method   | VNC (Port 5901), Web Browser via noVNC (Port 6901)                  |
| Proxy           | SOCKS5 (Dante) on Port 1080, HTTP (Tinyproxy) on Port 8888          |

## Key Features

- **Isolated GUI:** Run the Huawei UniVPN GUI client in a secure Docker container.
- **Remote Access:** Access via VNC clients or a web browser (noVNC).
- **Auto-Start & Keep-Alive:** The UniVPN client starts automatically. A keeper script monitors the process and can automatically restart it if it crashes or if the network connection is lost (Auto-Reconnect).
- **Proxies:**
  - **SOCKS5** (Port `1080`): Routes traffic through the VPN.
  - **HTTP** (Port `8888`): Chains to SOCKS5, allowing HTTP-based apps to use the VPN.
- **Configurable:** Managed via Docker Compose and `.env` files.
- **Privileges:** Includes `NET_ADMIN` and `TUN` device access required for VPNs.

## Prerequisites

- Docker installed on your host machine.
- Docker Compose installed (`docker-compose` or `docker compose`).
- The `tun` kernel module loaded on the host (`sudo modprobe tun`). Ensure `/dev/net/tun` exists.

## How to Use (Docker Compose Recommended)

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/zx900930/docker-univpn.git
    cd docker-univpn
    ```

2.  **Create `.env` File:**
    In the `docker-univpn` directory, create a file named `.env`. Copy the following content and adjust the values:

    ```dotenv
    # .env file

    # VPN Credentials (REQUIRED IF USING CLI IMAGE)
    VPN_USERNAME=your_username_here
    VPN_PASSWORD=your_password_here

    # Security & Network
    VNC_PASSWORD=YourStrongVncPassword123
    SPOOF_MAC=00:1A:2B:3C:4D:5E

    # --- Auto Reconnect Settings ---
    # Set to 'true' to enable auto-restart when network connectivity is lost
    AUTO_RECONNECT=true

    # The IP address to ping to check connectivity (e.g. 8.8.8.8 or your VPN's internal gateway)
    RECONNECT_PING_TARGET=8.8.8.8

    # Time (in seconds) to wait for login before starting connectivity checks
    RECONNECT_GRACE_PERIOD=60

    # Dante SOCKS5 outgoing VPN interface.
    # Set this to the VPN interface name created in your environment, such as ipsec_vnic.
    DANTE_INTERFACE=cnem_vnic
    ```

3.  **Start the Container:**

    `docker-compose.yml` includes a `build:` section alongside `image:`, so everything builds and runs locally — nothing is pulled from or pushed to Docker Hub.

    ```bash
    docker-compose up -d            # builds locally the first time, then just runs
    docker-compose up -d --build    # force a rebuild (e.g. after editing the Dockerfile)
    ```

4.  **Connect to the GUI:**

    - **VNC Client:** Connect to `localhost:5901` (Password: `VNC_PASSWORD`).
    - **Web Browser:** Go to `http://localhost:6901/vnc.html` (Password: `VNC_PASSWORD`).

5.  **Use the Proxies:**
    - **SOCKS5:** `localhost:1080`
    - **HTTP:** `localhost:8888`

    Dante waits for `DANTE_INTERFACE` before starting. The default is `cnem_vnic`; set it to the VPN interface name created in your environment, such as `ipsec_vnic`.
    After the VPN is connected, you can check the interface name inside the container:
    ```bash
    docker compose exec univpn ip -br link
    ```
    For the CLI compose file, use:
    ```bash
    docker compose -f docker-compose-cli.yml exec univpn ip -br link
    ```

## CLI-Only Docker Image

This repository also provides a `Dockerfile.cli` for building a command-line interface (CLI) only version of the UniVPN client. This image is suitable for environments where GUI access is not needed, such as CI/CD pipelines, scripting, headless servers, or arm64 hosts (see [Known Issues](#known-issues) below).

**New Dockerfile:** `Dockerfile.cli`
**Image tag used by `docker-compose-cli.yml`:** `triatk/univpn:latest-cli`

### Building the CLI Image

The existing CI workflow (`.github/workflows/docker-image.yml`) has been updated to automatically build and push the `triatk/univpn` image when changes are pushed to the `cli-only-image` branch.

To build it manually:

```bash
# Ensure you have the matching zip file in ./bin/
docker build -t triatk/univpn:latest-cli -f Dockerfile.cli .
```

### Creating a Connection Profile

The CLI client (`UniVPNCS`) needs a saved connection profile before it can log in. Create one **once**, interactively, using `UniVPNCS`'s own text menu — it never touches a GUI, so it works identically on amd64 and arm64:

```bash
docker run --rm -it \
  -v ./univpn_config:/home/vpnuser/UniVPN \
  --name univpn-setup \
  --user vpnuser -e HOME=/home/vpnuser \
  triatk/univpn:latest-cli \
  /usr/local/UniVPN/serviceclient/UniVPNCS
```

Walk through the menu:

```
Welcome to UniVPN!
1:New Connection          <- type 1
2:Exit

Please choose Connection Type
1:SSL VPN                 <- type 1
2:L2TP/IPSec
3:Cancel

                       SSL Configuration
1:Connection Name(Required):   <- type 1, then enter a name
2:Description:
3:Gateway Address(Required):   <- type 3, then enter your gateway IP/host
4:Port:443                     <- type 4, then enter the gateway port
5:Tunnel Mode:Auto-sensing
6:Certificate Authentication:Disable
7:GmSSL algorithm:Disable
8:Save                         <- type 8 once Name/Gateway/Port are filled in
9:Cancel
```

After saving, `2:Exit` to quit. This writes `sysconfig.ini` and `config/<ConnectionName>.ini` under `./univpn_config/` on the host — keep that directory out of version control (it's already in `.gitignore`), since it contains your gateway address.

### Using the CLI Image

Once a profile exists under `./univpn_config/`, set your credentials in `.env` (see `.envexample`) and start the container normally. `docker-compose-cli.yml` also has a `build:` section, so this builds locally instead of pulling from Docker Hub:

```bash
docker-compose -f docker-compose-cli.yml up -d            # builds locally the first time
docker-compose -f docker-compose-cli.yml up -d --build    # force a rebuild
docker-compose -f docker-compose-cli.yml logs -f
```

`univpn-keeper.sh.cli` drives `UniVPNCS` automatically: it picks the first saved connection from the menu, connects, and answers the username/password prompts using `VPN_USERNAME`/`VPN_PASSWORD` from the environment. The SOCKS5 (`1080`) and HTTP (`8888`) proxies come up the same way as the GUI image.

To force a reconnect:

```bash
docker exec univpn reconnect
```

## Auto-Reconnect & Manual Restart

The container uses a wrapper script (`univpn-keeper.sh`) to manage the VPN application.

### Auto-Reconnect Logic

If `AUTO_RECONNECT=true` is set in your `.env` file:

1.  The VPN starts.
2.  The script waits for `RECONNECT_GRACE_PERIOD` seconds (giving you time to type your password/2FA).
3.  After the grace period, it pings `RECONNECT_PING_TARGET` every 10 seconds.
4.  If the ping fails (network timeout), the script **kills the VPN process**.
5.  The loop detects the process exit and **immediately restarts a fresh VPN instance**.

### Manual Restart

If the VPN freezes or you need to restart it manually without restarting the whole container:

- **From Host Terminal (GUI image):**
  ```bash
  docker exec univpn-vnc reconnect
  ```
- **From Host Terminal (CLI image):**
  ```bash
  docker exec univpn reconnect
  ```
- **From Inside VNC (GUI image only):**
  Open the Fluxbox terminal (Right Click -> Applications -> Shells -> Bash) and type:
  ```bash
  reconnect
  ```

## Inside the Container

- The GUI image runs an `Xvfb` virtual X server with `x11vnc` serving the VNC connection, and a Fluxbox window manager on top.
- **UniVPN GUI** is launched by `/usr/local/bin/univpn-keeper.sh`.
- **Dante (SOCKS5)** and **Tinyproxy (HTTP)** run in the background via Supervisor.

## Configuration & Persistence

- **Environment Variables:** All settings are controlled via the `.env` file.
- **Persistence:** To save your VPN profiles and settings, uncomment the volume in `docker-compose.yml`:
  ```yaml
  volumes:
    - ./univpn_config:/home/vpnuser/UniVPN
  ```

## Troubleshooting

- **Looping Restarts:** If you see the VPN opening and closing repeatedly, check if `RECONNECT_PING_TARGET` is reachable. If the VPN blocks internet access but allows internal IPs, set the target to an internal server IP.
- **Not enough time to login:** Increase `RECONNECT_GRACE_PERIOD` in the `.env` file.
- **Container Crashing:** Check logs: `docker-compose logs univpn`. Note that `docker-compose logs` only shows supervisor's own output — the actual VPN client log lives at `/var/log/supervisor/univpn-keeper_stdout.log` (GUI image) or `univpn-keeper_stdout.log`/`univpn-keeper_stderr.log` (CLI image) inside the container.

## Known Issues

- **GUI image on `linux/arm64`: creating a connection via "New Connection" can crash the UniVPN window (screen goes black on the first click/keypress in the dialog).** This is a crash inside `libxkbcommon`/Qt5's XCB keyboard handling (`QXcbKeyboard::updateKeymap` → `xkb_keymap_unref` on an invalid pointer) that reproduces regardless of VNC backend (TigerVNC's Xvnc or Xvfb+x11vnc) — it is not something fixable from this project's Dockerfile/config. The keeper script restarts the crashed process automatically within a few seconds, but you can lose dialog input repeatedly.

  **Workaround:** create the connection profile through the CLI client's text menu instead — see [Creating a Connection Profile](#creating-a-connection-profile) above. It never touches Qt/X11, so it is unaffected by this bug on any architecture. Once a profile exists under `./univpn_config/`, the GUI's main window (selecting an existing connection and clicking **Connect**) works normally; only the **New Connection** dialog is affected.

## License

The Dockerfile and scripts in this repository are provided under the [MIT License](LICENSE). The Huawei software included in `./bin` is proprietary.
