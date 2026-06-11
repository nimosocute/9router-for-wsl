# 9Router for WSL

Run 9Router reliably inside Windows Subsystem for Linux (WSL).

## The Problem

9Router can run inside WSL, but daily use can be awkward:

- the server may stop when the WSL session is closed or the distro goes idle
- users have to remember to start 9Router manually before using CLI tools
- the dashboard is easy to lose when 9Router is running in background mode
- Windows login does not automatically mean the WSL service is running

That creates a fragile workflow: 9Router is installed, but the proxy is not always alive when tools expect `http://127.0.0.1:20128/v1`.

## The Solution

9Router for WSL sets up a small WSL-native service around an existing 9Router installation:

- a `systemd --user` service keeps 9Router running in the background
- `Restart=always` brings it back if the process exits
- a dashboard opener runs after the API is ready
- a Windows Startup entry calls WSL on login and starts the service
- model, provider, and credential configuration stay inside 9Router

This installer:

- creates a `systemd --user` service with `Restart=always`
- opens the 9Router dashboard after the server is ready
- creates a Windows Startup entry that starts the WSL service on login
- leaves Codex/model configuration untouched

It does **not** edit `~/.codex/config.toml`, select models, add provider credentials, or configure 9Router routing. Users should do that themselves in the 9Router dashboard.

## Credit

This project is built for [Windows Subsystem for Linux](https://learn.microsoft.com/windows/wsl/), which makes it possible to run Linux developer services on Windows while still integrating with the Windows desktop.

## Requirements

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

## Install

From inside WSL:

```bash
npm install -g 9router
```

Then run the autostart setup:

```bash
curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-for-wsl/main/install.sh | bash
```

The setup command creates the WSL `systemd` user service and, when possible, also creates the Windows Startup entry from WSL.

If you want a single copy-paste command after opening WSL:

```bash
npm install -g 9router && curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-for-wsl/main/install.sh | bash
```

For local development only, you can clone and run:

```bash
git clone https://github.com/nimosocute/9router-for-wsl.git
cd 9router-for-wsl
bash install.sh
```

## Daily Use

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

## Commands

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

## Options

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

## Uninstall

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

## Notes

The installer intentionally avoids configuring models or credentials. If Codex, Claude Code, or another tool reports an error like "No active credentials for provider", open the 9Router dashboard and configure the provider/model routing there.
