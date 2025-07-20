#!/bin/bash
set -euo pipefail

# 🟡 Colors
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
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
    echo -e "${RED}❌ $1${RESET}"
}

# 🧠 Args
PLACE=${1:-}
if [ -z "$PLACE" ]; then
    print_error "Usage: $0 <place-name>"
    exit 1
fi

# 📁 Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
BASE_DIR="$ROOT_DIR/sources/base"
PLACE_DIR="$ROOT_DIR/sources/$PLACE"

if [ ! -f "$ROOT_DIR/package.json" ]; then
    print_error "Required file not found: package.json in root"
    exit 1
fi

cd "$ROOT_DIR"

print_step "🧹 Cleaning output and build files..."
rm -rf out
rm -f "$BASE_DIR/build/default.project.json" "$PLACE_DIR/build/default.project.json"
rm -f "$BASE_DIR/build/tsconfig.json" "$PLACE_DIR/build/tsconfig.json"
rm -rf "$BASE_DIR/build/node_modules" "$PLACE_DIR/build/node_modules"
print_done "Clean complete."

# 🔗 Symlink node_modules
link_node_modules() {
    print_step "🔗 Linking node_modules → $1"
    ln -sf "$ROOT_DIR/node_modules" "$1/build/node_modules"
    print_done "Linked node_modules for $1"
}
link_node_modules "$BASE_DIR"
link_node_modules "$PLACE_DIR"

# 📦 npm install check
PKG_JSON="$ROOT_DIR/package.json"
PKG_LOCK="$ROOT_DIR/package-lock.json"
NPM_STAMP="$ROOT_DIR/.npm_installed_stamp"

if [ ! -f "$NPM_STAMP" ] || [ "$PKG_JSON" -nt "$NPM_STAMP" ] || [ "$PKG_LOCK" -nt "$NPM_STAMP" ]; then
    print_step "📦 Running npm install (dependencies changed)..."
    npm install
    touch "$NPM_STAMP"
    print_done "npm install complete."
else
    print_step "📦 Skipping npm install (no changes)."
    print_done "npm install skipped."
fi

# 🔧 Project setup
print_step "⚙️ Running rokit install..."
rokit install --no-trust-check
print_done "rokit install complete."

print_step "🌳 Generating Rojo Trees..."
node "$ROOT_DIR/scripts/java/genRojoTree.js" base
node "$ROOT_DIR/scripts/java/genRojoTree.js" "$PLACE"
print_done "Rojo Trees generated."

print_step "🧠 Generating TS Configs..."
node "$ROOT_DIR/scripts/java/genTSConfig.js" base
node "$ROOT_DIR/scripts/java/genTSConfig.js" "$PLACE"
print_done "TS Configs generated."

# 🚀 Compilation
print_step "📁 Preparing output directory..."
mkdir -p "$ROOT_DIR/out/include"
print_done "Output directory ready."

print_step "🚀 Starting TypeScript compilation..."

npx rbxtsc -w -p "$BASE_DIR/build/tsconfig.json" --rojo "$BASE_DIR/build/default.project.json" -i out/include &
BASE_PID=$!

npx rbxtsc -w -p "$PLACE_DIR/build/tsconfig.json" --rojo "$PLACE_DIR/build/default.project.json" -i out/include &
PLACE_PID=$!

# Trap Ctrl+C to kill both watchers cleanly
trap 'echo -e "\n${YELLOW}⚠️ Interrupt received, stopping watchers...${RESET}"; kill $BASE_PID $PLACE_PID; exit 1' SIGINT

wait $BASE_PID $PLACE_PID

print_done "Compilation complete."
