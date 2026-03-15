<div align="center">
  <img src="logo.svg" alt="Macpronix Logo" width="160" />
  <h1>macProNix</h1>
  <p><b>Industrial Infrastructure for the Late 2013 Mac Pro</b></p>
  
  <p>
    <a href="https://nixos.org"><img src="https://img.shields.io/badge/OS-NixOS-5277c3?style=for-the-badge&logo=nixos&logoColor=white" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" /></a>
  </p>
</div>

## Overview

**Macpronix** turns your "Trashcan" Mac Pro (6,1) into a high-performance, declarative Linux server. It provides a stable, immutable infrastructure foundation for self-hosting complex containerized stacks and services.

## Architecture

| Component | Stack | Responsibility |
| :--- | :--- | :--- |
| **Kernel** | <img src="https://img.shields.io/badge/Broadcom-Drivers-red?style=flat&logo=broadcom&logoColor=white" height="20" /> | Proprietary 6,1 hardware support (`wl` drivers, thermals). |
| **Network** | <img src="https://img.shields.io/badge/NetworkManager-WPA_Supplicant-black?style=flat&logo=linux&logoColor=white" height="20" /> | Legacy backend support for stable BCM4360 connectivity. |
| **Cluster** | <img src="https://img.shields.io/badge/Tailscale-Mesh-white?style=flat&logo=tailscale&logoColor=black" height="20" /> | Zero-config mesh networking for headless management. |

## Security Architecture & Maintenance

Macpronix implements a comprehensive, defense-in-depth security posture designed for unattended operation:

*   **Zero-Trust Networking**: SSH (port 22) is completely firewalled off from the public internet. Management access is strictly bound to the Tailscale VPN mesh.
*   **Defense-in-Depth**: `Fail2Ban` actively monitors and blocks suspicious internal network behavior.
*   **Access Control**: Standard passwordless `sudo` is disabled. Administrators must use PAM SSH Agent Authentication (`ssh -A`) to escalate privileges, ensuring the root user cannot be accessed without the active presence of the administrator's forwarded private key.
*   **System Hardening**: Mandatory Access Control (MAC) is enforced via **AppArmor**. Kernel auditing (`auditd`) is active, and the kernel attack surface is reduced (unprivileged eBPF disabled, `dmesg` restricted).
*   **Automated Upgrades**: A systemd timer automatically runs `macpronix upgrade` daily. This ensures security patches from upstream NixOS are applied without manual intervention, while structural infrastructure changes remain strictly gated behind a manual git `macpronix sync`.

## Usage

The node is managed via `macpronix`, a CLI tool that abstracts NixOS rebuilds, enforces git state integrity, and manages hardware configuration.

```text
   __  __          _____ _____  _____   ____  _   _ _______   __
  |  \/  |   /\   / ____|  __ \|  __ \ / __ \| \ | |_   _\ \ / /
  | \  / |  /  \ | |    | |__) | |__) | |  | |  \| | | |  \ V / 
  | |\/| | / /\ \| |    |  ___/|  _  /| |  | | . ` | | |   > <  
  | |  | |/ ____ \ |____| |    | | \ \| |__| | |\  |_| |_ / . \ 
  |_|  |_/_/    \_\_____|_|    |_|  \_\\____/|_| \_|_____/_/ \_\
```

### Install

To bootstrap a new MacPro node or deploy locally, clone the repository and configure your SSH keys:

```bash
git clone https://github.com/tarantula-org/macpronix ~/macpronix
cd ~/macpronix
```

For security reasons, an `admin.keys` file is required before deployment. Add your public SSH keys to this file:

```bash
echo "ssh-ed25519 AAAAC3NzaC1... user@host" > hosts/trashcan/admin.keys
```

After adding your keys, run the install target:

```bash
make install
```

### Sync

To fetch and apply the latest configuration from the upstream repository, syncing the git state and triggering a NixOS rebuild:

```bash
macpronix sync
```

### Upgrade Packages

To upgrade system dependencies and update the flake lock file:

```bash
macpronix upgrade
```