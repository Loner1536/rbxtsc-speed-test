#!/bin/bash
set -e

# 🟡 Terminal Colors
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"

print_step() {
    echo -e "${BLUE}➤${RESET} ${BOLD}$1${RESET}"
}

print_done() {
    echo -e "${GREEN}✔${RESET} ${BOLD}$1${RESET}\n"
}

print_warn() {
    echo -e "${YELLOW}⚠${RESET} ${BOLD}$1${RESET}"
}

print_error() {
    echo -e "${RED}❌${RESET} ${BOLD}$1${RESET}"
}

# Step 1: Fix workspace permissions
print_step "[1/3] Fixing workspace permissions"
if [ "$(id -u)" != "$(stat -c '%u' /workspace)" ]; then
    if [ -w /workspace ]; then
        print_warn "Fixing workspace permissions for CI environment"
    else
        print_warn "Using sudo to fix workspace permissions"
        sudo chown -R "$(id -u):$(id -g)" /workspace || true
    fi
fi
print_done "Workspace permissions fixed"

# Step 2: Install node packages
print_step "[2/3] Installing node packages"
npm install
print_done "Node packages installed"

# Step 3: Install rokit packages
print_step "[3/3] Installing rokit packages"
rokit install --no-trust-check
print_done "Rokit packages installed"
