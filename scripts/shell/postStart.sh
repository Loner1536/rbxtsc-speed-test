#!/bin/bash
set -e

echo "[1/3] Fixing workspace permissions"
if [ "$(id -u)" != "$(stat -c '%u' /workspace)" ]; then
    if [ -w /workspace ]; then
        echo "Fixing workspace permissions for CI environment"
    else
        echo "Using sudo to fix workspace permissions"
        sudo chown -R "$(id -u):$(id -g)" /workspace || true
    fi
fi

echo "[2/3] Instsalling node packages"
npm install

echo "[3/3] Installing rokit packages"
rokit install --no-trust-check