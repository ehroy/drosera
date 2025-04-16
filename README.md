# 🚀 Drosera Network Auto Installer

Skrip bash ini akan membantu Anda mengatur seluruh environment untuk berpartisipasi dalam testnet **Drosera Network** secara otomatis. Termasuk instalasi dependencies, deployment Trap, dan setup sebagai Operator.

> 🛠️ **Author**: [ehroy](https://github.com/ehroy)

---

## ✅ Fitur Utama

- Instalasi dependencies lengkap (Docker, Foundry, Bun, CLI Drosera)
- Setup & deploy Trap di jaringan testnet
- Konfigurasi private trap & whitelist operator
- Setup service Operator sebagai `systemd`
- Logging & error handling otomatis
- Support OS: Ubuntu 20.04 / 22.04

---

## 🔰 System Requirements

| Resource  | Minimum |
|-----------|---------|
| CPU       | 2 Cores |
| RAM       | 4 GB    |
| Storage   | 20 GB   |

---

## 📦 Cara Instalasi

### 1. Clone Repository

```bash
git clone https://github.com/ehroy/drosera-auto-installer.git
cd drosera-auto-installer
chmod +x install.sh
./run.sh
