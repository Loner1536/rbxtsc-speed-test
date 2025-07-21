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

# Default INCLUDE_BASE to false if PLACE is "base", else true
INCLUDE_BASE=${2:-}
if [ -z "$INCLUDE_BASE" ]; then
    if [ "$PLACE" = "base" ]; then
        INCLUDE_BASE="false"
    else
        INCLUDE_BASE="true"
    fi
fi

# 📁 Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."

SOURCES_DIR="$ROOT_DIR/sources"
BASE_DIR="$SOURCES_DIR/base"
PLACE_DIR="$SOURCES_DIR/$PLACE"

# Since tsconfig and project jsons are directly under sources/
BASE_TSCONFIG="$SOURCES_DIR/base.tsconfig.json"
PLACE_TSCONFIG="$SOURCES_DIR/$PLACE.tsconfig.json"

BASE_PROJECT="$SOURCES_DIR/base.project.json"
PLACE_PROJECT="$SOURCES_DIR/$PLACE.project.json"

if [ ! -f "$SOURCES_DIR/package.json" ]; then
    print_error "Required file not found: package.json in sources root"
    exit 1
fi

print_step "🧹 Cleaning output and build files..."

rm -f "$ROOT_DIR/dist/out/base.tsbuildinfo" "$ROOT_DIR/dist/out/$PLACE.tsbuildinfo"
rm -f "$BASE_PROJECT" "$PLACE_PROJECT"
rm -f "$BASE_TSCONFIG" "$PLACE_TSCONFIG"
rm -rf "$BASE_DIR/node_modules" "$PLACE_DIR/node_modules"
rm -rf out

print_done "Clean complete."

print_step "📦 Ensuring roblox-ts is installed..."
npm install --prefix $SOURCES_DIR
print_done "roblox-ts installed."

print_step "⚙️ Running rokit install..."
rokit install --no-trust-check
print_done "rokit install complete."

print_step "🌳 Generating Rojo Trees..."
node "$ROOT_DIR/scripts/java/genRojoTree.js" base false
node "$ROOT_DIR/scripts/java/genRojoTree.js" "$PLACE" "$INCLUDE_BASE"
print_done "Rojo Trees generated."

print_step "🧠 Generating TS Configs..."
node "$ROOT_DIR/scripts/java/genTSConfig.js" base
node "$ROOT_DIR/scripts/java/genTSConfig.js" "$PLACE"
print_done "TS Configs generated."

print_step "📁 Preparing output directory..."
rm -rf "$ROOT_DIR/dist/include"
print_done "Output directory ready."

print_step "🚀 Starting TypeScript compilation..."

if [[ "$INCLUDE_BASE" != "false" ]]; then
    rbxtsc -w -p "$BASE_TSCONFIG" --rojo "$BASE_PROJECT" -i dist/include &
    BASE_PID=$!
else
    BASE_PID=""
fi

rbxtsc -w -p "$PLACE_TSCONFIG" --rojo "$PLACE_PROJECT" -i dist/include &
PLACE_PID=$!

trap 'echo -e "\n${YELLOW}⚠️ Interrupt received, stopping watchers...${RESET}"; [[ -n "$BASE_PID" ]] && kill $BASE_PID; kill $PLACE_PID; exit 1' SIGINT

if [[ -n "$BASE_PID" ]]; then
    wait $BASE_PID $PLACE_PID
else
    wait $PLACE_PID
fi

print_done "Compilation complete."
