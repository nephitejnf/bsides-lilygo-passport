#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Lab: BSides BadUSB — USB HID Trust Demo
#
# Called by setup-labs.sh. Expects ESP-IDF to already be installed
# (run setup-base.sh first).
#
# What it does:
#   1. Clones the lab project (or pulls latest)
#   2. Sets ESP32-S3 target and pre-warms the build cache
#   3. Creates ~/flag.txt
# ─────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────
LAB_REPO="https://github.com/YOUR_ORG/bsides-badusb.git"   # ← UPDATE THIS
LAB_DIR="$HOME/bsides-badusb"
FLAG_TEXT="FLAG{HID_TRUST_IS_BLIND}"

# ── Colors ─────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }

# ── Preflight ──────────────────────────────────────────────────────
if ! command -v idf.py > /dev/null 2>&1; then
    echo "ERROR: idf.py not found. Run setup-base.sh first." >&2
    exit 1
fi

# ── Clone / update ─────────────────────────────────────────────────
if [ -d "$LAB_DIR" ]; then
    info "Lab project already at $LAB_DIR — pulling latest..."
    cd "$LAB_DIR"
    git pull --ff-only || warn "Could not pull — using existing checkout."
else
    info "Cloning lab project..."
    git clone "$LAB_REPO" "$LAB_DIR"
fi

cd "$LAB_DIR"

# ── Build ──────────────────────────────────────────────────────────
info "Setting target to ESP32-S3..."
idf.py set-target esp32s3

info "Pre-warming build cache (first build takes 2-3 minutes)..."
idf.py build

# ── Flag file ──────────────────────────────────────────────────────
info "Creating ~/flag.txt..."
echo "$FLAG_TEXT" > "$HOME/flag.txt"

# ── Done ───────────────────────────────────────────────────────────
echo ""
info "BadUSB lab ready!"
echo "  Project:    $LAB_DIR"
echo "  Flag:       ~/flag.txt → $FLAG_TEXT"
echo "  Workflow:   edit main/hid_keyboard.c → idf.py build flash"
