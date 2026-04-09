# Lab Machine Setup

Scripts for provisioning Lubuntu lab machines before the event.

## Structure

```
setup/
├── setup-base.sh           # One-time machine tooling (ESP-IDF, USB access)
├── setup-labs.sh           # Discovers and runs all lab setup scripts
└── labs/
    └── 01-badusb/
        └── setup.sh        # BadUSB lab — clone, build, flag file
```

## Quickstart

```bash
# 1. Install base tooling (once per machine)
./setup-base.sh

# 2. Log out and back in (required if user groups changed)

# 3. Run all lab setups
./setup-labs.sh

# 4. Or run a specific lab by name
./setup-labs.sh badusb
```

---

## setup-base.sh

Run **once per machine** before the event. Lab-agnostic.

**What it does:**
- Installs system packages required by ESP-IDF (`git`, `cmake`, `ninja-build`, etc.)
- Clones and installs ESP-IDF `v5.3.2` (ESP32-S3 target only) to `~/esp/esp-idf`
- Adds `source ~/esp/esp-idf/export.sh` to `~/.bashrc` so `idf.py` is always in PATH
- Adds a udev rule for VID `303a` (Espressif) so USB devices are accessible without `sudo` — covers both the ROM bootloader (flashing mode) and running firmware
- Adds the current user to the `dialout` and `plugdev` groups for `/dev/ttyACM*` serial access

> **Note:** If group membership changes, the user must log out and back in before flashing will work without `sudo`.

---

## setup-labs.sh

Discovers and runs every `labs/*/setup.sh` in alphabetical order.

```bash
./setup-labs.sh              # run all labs
./setup-labs.sh badusb       # run only labs whose directory name contains "badusb"
```

Each lab script runs in its own bash process — a failure in one lab is reported but does not abort the others.

**Environment variables passed to each lab's setup.sh:**

| Variable | Value |
|----------|-------|
| `LABS_BASE_DIR` | Absolute path to the `labs/` directory |
| `ESP_IDF_DIR` | Path to ESP-IDF (`~/esp/esp-idf`) |
| `LAB_NAME` | The directory name of the lab being set up |

---

## Adding a new lab

1. Create a directory under `labs/` — use a numeric prefix to control order:
   ```
   labs/02-my-new-lab/
   ```

2. Add a `setup.sh` inside it. It should be self-contained:
   - Clone or copy the lab project
   - Build any firmware (the build cache will already be warm if the same project)
   - Create any required files (flags, configs, etc.)
   - Print a short summary when done

3. Check that `idf.py` is available at the start if your lab uses ESP-IDF:
   ```bash
   if ! command -v idf.py > /dev/null 2>&1; then
       echo "ERROR: idf.py not found. Run setup-base.sh first." >&2
       exit 1
   fi
   ```

4. `setup-labs.sh` will pick it up automatically — no registration needed.

**Minimal lab setup.sh template:**
```bash
#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }

# your setup steps here

info "My lab is ready."
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `idf.py: command not found` | Run `source ~/.bashrc` or open a new terminal |
| `Permission denied` on `/dev/ttyACM0` | Log out and back in after running `setup-base.sh` |
| `git clone` fails | Check network access; confirm `LAB_REPO` URL is set correctly in the lab's `setup.sh` |
| Build fails with missing components | Delete the `build/` directory in the lab project and run `idf.py build` again |
| udev rule not taking effect | Run `sudo udevadm control --reload-rules && sudo udevadm trigger`, then unplug and replug the device |
