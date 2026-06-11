# 9Router for WSL

Languages: [English](#english) | [Tiếng Việt](#tiếng-việt)

## English

### What This Does

9Router for WSL is a small setup layer for running 9Router reliably inside Windows Subsystem for Linux.

It does not replace 9Router. It supports an existing 9Router installation by adding:

- a WSL `systemd --user` service
- automatic restart if 9Router exits
- dashboard opening after the API is ready
- a Windows Startup entry that starts the WSL service on login

It does **not** configure models, providers, credentials, or `~/.codex/config.toml`. Users should configure those inside the 9Router dashboard.

### The Problem

9Router can run inside WSL, but daily use can be fragile:

- the server may stop when the WSL session closes or the distro goes idle
- users have to start 9Router manually before using CLI tools
- the dashboard is easy to lose when 9Router runs in background mode
- Windows login does not automatically mean the WSL service is running

That means tools expecting `http://127.0.0.1:20128/v1` may fail even though 9Router is installed.

### The Solution

This repo installs a WSL-native service around 9Router:

- `systemd --user` keeps 9Router running
- `Restart=always` brings it back if it exits
- a dashboard opener runs after `/v1/models` is ready
- a Windows Startup entry calls WSL and starts the service on login
- model/provider routing stays fully controlled by 9Router

### Credit

9Router for WSL is a support utility for [decolua/9router](https://github.com/decolua/9router). 9Router itself is created and maintained by the 9Router project.

This project is built for [Windows Subsystem for Linux](https://learn.microsoft.com/windows/wsl/), which makes it possible to run Linux developer services on Windows while integrating with the Windows desktop.

### Contributing

Issues and pull requests are welcome. Useful contributions include bug reports, distro-specific fixes, better WSL startup handling, documentation improvements, and safer install/uninstall behavior.

Please keep this repo focused on WSL support for 9Router. Model routing, provider credentials, and 9Router core features should stay in the upstream 9Router project.

### Requirements

- Windows with WSL2
- A Linux distro with `systemd` enabled
- `bash`, `curl`, `systemctl`
- 9Router already installed in WSL

For WSL, `/etc/wsl.conf` should include:

```ini
[boot]
systemd=true
```

After changing that file, restart WSL from Windows:

```powershell
wsl --shutdown
```

Then open the distro again.

### Install

From inside WSL, install 9Router first:

```bash
npm install -g 9router
```

Then run the WSL setup:

```bash
curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-for-wsl/main/install.sh | bash
```

Single copy-paste command:

```bash
npm install -g 9router && curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-for-wsl/main/install.sh | bash
```

For local development:

```bash
git clone https://github.com/nimosocute/9router-for-wsl.git
cd 9router-for-wsl
bash install.sh
```

### Daily Use

After installation:

1. Log in to Windows.
2. The Windows Startup entry calls WSL.
3. WSL starts `9router.service`.
4. 9Router runs in the background and restarts if it exits.
5. The dashboard opens after the API is ready.

API endpoint:

```text
http://127.0.0.1:20128/v1
```

Dashboard:

```text
http://localhost:20128/dashboard
```

### Commands

Check status:

```bash
systemctl --user status 9router.service
```

Restart:

```bash
systemctl --user restart 9router.service
```

Stop:

```bash
systemctl --user stop 9router.service
```

Open dashboard manually:

```bash
~/bin/open-9router-dashboard.sh
```

Check API:

```bash
curl http://127.0.0.1:20128/v1/models
```

### Options

Set environment variables before running `install.sh`.

Use a different port:

```bash
9ROUTER_PORT=20129 bash install.sh
```

Bind to a different host:

```bash
9ROUTER_HOST=0.0.0.0 bash install.sh
```

Do not open the dashboard automatically:

```bash
OPEN_DASHBOARD=0 bash install.sh
```

Do not create a Windows Startup entry:

```bash
ENABLE_WINDOWS_STARTUP=0 bash install.sh
```

Use a custom npm global prefix:

```bash
NPM_CONFIG_PREFIX="$HOME/.npm-global" bash install.sh
```

### Uninstall

```bash
bash uninstall.sh
```

This removes:

- the `systemd --user` service
- the dashboard opener script
- the Windows Startup entry

It does not remove:

- the 9Router npm package
- 9Router user data
- provider credentials
- Codex config

### Notes

The installer intentionally avoids configuring models or credentials. If Codex, Claude Code, or another tool reports an error like "No active credentials for provider", open the 9Router dashboard and configure the provider/model routing there.

## Tiếng Việt

### Repo Này Làm Gì

9Router for WSL là một lớp setup nhỏ giúp chạy 9Router ổn định bên trong Windows Subsystem for Linux.

Repo này không thay thế 9Router. Nó hỗ trợ một bản 9Router đã được cài sẵn bằng cách thêm:

- service WSL `systemd --user`
- tự khởi động lại nếu 9Router thoát/crash
- tự mở dashboard sau khi API sẵn sàng
- Windows Startup entry để gọi WSL và start service khi đăng nhập Windows

Repo này **không** cấu hình model, provider, credential, hoặc `~/.codex/config.toml`. Người dùng tự cấu hình các phần đó trong dashboard của 9Router.

### Vấn Đề

9Router có thể chạy trong WSL, nhưng dùng hằng ngày dễ bị phiền:

- server có thể dừng khi session WSL đóng hoặc distro idle
- người dùng phải nhớ start 9Router thủ công trước khi dùng CLI tools
- dashboard dễ bị mất khi 9Router chạy nền
- đăng nhập Windows không đồng nghĩa service trong WSL đã chạy

Kết quả là các tool đang trông chờ endpoint `http://127.0.0.1:20128/v1` có thể lỗi dù 9Router đã được cài.

### Giải Pháp

Repo này tạo một service WSL-native bao quanh 9Router:

- `systemd --user` giữ 9Router chạy nền
- `Restart=always` kéo 9Router lên lại nếu process thoát
- script mở dashboard chạy sau khi `/v1/models` sẵn sàng
- Windows Startup entry gọi WSL và start service khi đăng nhập
- routing model/provider vẫn nằm hoàn toàn trong 9Router

### Credit

9Router for WSL là tiện ích hỗ trợ cho [decolua/9router](https://github.com/decolua/9router). Bản thân 9Router được tạo và duy trì bởi dự án 9Router.

Dự án này được xây cho [Windows Subsystem for Linux](https://learn.microsoft.com/windows/wsl/), nền tảng giúp chạy dịch vụ Linux trên Windows và vẫn tích hợp với desktop Windows.

### Contributing

Issue và pull request đều được chào đón. Những đóng góp hữu ích gồm báo lỗi, sửa lỗi theo từng distro, cải thiện cơ chế startup trong WSL, cải thiện tài liệu, và làm install/uninstall an toàn hơn.

Repo này nên tập trung vào phần hỗ trợ WSL cho 9Router. Routing model, provider credentials, và tính năng lõi của 9Router nên nằm ở upstream 9Router.

### Yêu Cầu

- Windows có WSL2
- Linux distro đã bật `systemd`
- `bash`, `curl`, `systemctl`
- 9Router đã được cài trong WSL

Trong WSL, `/etc/wsl.conf` nên có:

```ini
[boot]
systemd=true
```

Sau khi sửa file đó, restart WSL từ Windows:

```powershell
wsl --shutdown
```

Sau đó mở lại distro.

### Cài Đặt

Trong WSL, cài 9Router trước:

```bash
npm install -g 9router
```

Sau đó chạy setup cho WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-for-wsl/main/install.sh | bash
```

Một dòng copy-paste:

```bash
npm install -g 9router && curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-for-wsl/main/install.sh | bash
```

Nếu muốn clone để phát triển:

```bash
git clone https://github.com/nimosocute/9router-for-wsl.git
cd 9router-for-wsl
bash install.sh
```

### Sử Dụng Hằng Ngày

Sau khi cài:

1. Đăng nhập Windows.
2. Windows Startup entry gọi WSL.
3. WSL start `9router.service`.
4. 9Router chạy nền và tự restart nếu thoát.
5. Dashboard tự mở sau khi API sẵn sàng.

API endpoint:

```text
http://127.0.0.1:20128/v1
```

Dashboard:

```text
http://localhost:20128/dashboard
```

### Lệnh Hay Dùng

Kiểm tra trạng thái:

```bash
systemctl --user status 9router.service
```

Restart:

```bash
systemctl --user restart 9router.service
```

Dừng:

```bash
systemctl --user stop 9router.service
```

Mở dashboard thủ công:

```bash
~/bin/open-9router-dashboard.sh
```

Kiểm tra API:

```bash
curl http://127.0.0.1:20128/v1/models
```

### Tuỳ Chọn

Đặt biến môi trường trước khi chạy `install.sh`.

Dùng port khác:

```bash
9ROUTER_PORT=20129 bash install.sh
```

Bind host khác:

```bash
9ROUTER_HOST=0.0.0.0 bash install.sh
```

Không tự mở dashboard:

```bash
OPEN_DASHBOARD=0 bash install.sh
```

Không tạo Windows Startup entry:

```bash
ENABLE_WINDOWS_STARTUP=0 bash install.sh
```

Dùng npm global prefix khác:

```bash
NPM_CONFIG_PREFIX="$HOME/.npm-global" bash install.sh
```

### Gỡ Cài Đặt

```bash
bash uninstall.sh
```

Lệnh này xoá:

- service `systemd --user`
- script mở dashboard
- Windows Startup entry

Lệnh này không xoá:

- package npm của 9Router
- dữ liệu người dùng của 9Router
- provider credentials
- Codex config

### Ghi Chú

Installer cố ý không cấu hình model hoặc credential. Nếu Codex, Claude Code, hoặc tool khác báo lỗi kiểu "No active credentials for provider", hãy mở dashboard 9Router và tự cấu hình provider/model routing trong đó.
