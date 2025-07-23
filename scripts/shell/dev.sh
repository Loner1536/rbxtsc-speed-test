#!/bin/bash
set -euo pipefail

# 🟡 Colors
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"

print_step() {
    echo -e "${BLUE}➤${RESET} ${BOLD}$1${RESET}"
}

print_done() {
    echo -e "${GREEN}✔${RESET} ${BOLD}$1${RESET}\n"
}

print_error() {
    echo -e "${RED}❌ $1${RESET}"
}

# 🧠 Args
PLACE=${1:-}
if [ -z "$PLACE" ]; then
    print_error "Usage: $0 <place-name> [include-common]"
    exit 1
fi

INCLUDE_COMMON=${2:-}
if [ -z "$INCLUDE_COMMON" ]; then
    if [ "$PLACE" = "common" ]; then
        INCLUDE_COMMON="false"
    else
        INCLUDE_COMMON="true"
    fi
fi

# 📁 Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."

SOURCES_DIR="$ROOT_DIR/sources"
COMMON_TSCONFIG="$ROOT_DIR/common.tsconfig.json"
PLACE_TSCONFIG="$ROOT_DIR/$PLACE.tsconfig.json"
COMMON_PROJECT="$ROOT_DIR/common.project.json"
PLACE_PROJECT="$ROOT_DIR/$PLACE.project.json"

OUTPUT_DIR="$ROOT_DIR/dist/out"
INCLUDE_DIR="$ROOT_DIR/dist/include"

# Validate project
if [ ! -f "$ROOT_DIR/package.json" ]; then
    print_error "package.json not found in root ($ROOT_DIR)"
    exit 1
fi

mkdir -p "dist/out"

print_step "🧹 Cleaning build files and old configs..."

find "$ROOT_DIR" -maxdepth 1 -type f -name "*.tsconfig.json" ! -name "tsconfig.json" -exec rm -f {} \;
find "$ROOT_DIR" -maxdepth 1 -type f -name "*.project.json" -exec rm -f {} \;
find "$ROOT_DIR/dist/out" -type f -name "*.tsbuildinfo" -exec rm -f {} \;
rm -f flamework.build

print_done "Clean complete."

print_step "📦 Installing npm dependencies (root)..."
npm install --prefix "$ROOT_DIR"
print_done "npm install complete."

print_step "⚙️ Generating Rojo Trees and TS Configs..."

node "$ROOT_DIR/scripts/js/genRojoTree.js" common false
node "$ROOT_DIR/scripts/js/genRojoTree.js" "$PLACE" "$INCLUDE_COMMON"

node "$ROOT_DIR/scripts/js/genTSConfig.js" common
node "$ROOT_DIR/scripts/js/genTSConfig.js" "$PLACE"

print_done "Generated Rojo Trees and TS Configs."

print_step "🚀 Starting TypeScript compilation in watch mode..."

if [[ "$INCLUDE_COMMON" == "true" ]]; then
    npx rbxtsc -w -p "$COMMON_TSCONFIG" --rojo "$COMMON_PROJECT" -i "$INCLUDE_DIR" &
    COMMON_PID=$!
else
    COMMON_PID=""
fi

npx rbxtsc -w -p "$PLACE_TSCONFIG" --rojo "$PLACE_PROJECT" -i "$INCLUDE_DIR" &
PLACE_PID=$!

print_step "⏳ Waiting for compiled output to exist..."

EXPECTED_PATH="$OUTPUT_DIR/$PLACE/client"

MAX_WAIT=15 # seconds
TIME_WAITED=0

while [ ! -d "$EXPECTED_PATH" ] && [ "$TIME_WAITED" -lt "$MAX_WAIT" ]; do
    sleep 1
    TIME_WAITED=$((TIME_WAITED + 1))
done

if [ ! -d "$EXPECTED_PATH" ]; then
    print_error "Timed out waiting for TypeScript output at: $EXPECTED_PATH"
    [[ -n "$COMMON_PID" ]] && kill $COMMON_PID || true
    kill $PLACE_PID || true
    exit 1
fi

print_done "Output exists: $EXPECTED_PATH"

print_step "🛠️  Starting Rojo server..."
rojo serve "$PLACE_PROJECT" &
ROJO_PID=$!

trap 'echo -e "\n${YELLOW}⚠️ Interrupt received, stopping processes...${RESET}"; [[ -n "$COMMON_PID" ]] && kill $COMMON_PID; kill $PLACE_PID; kill $ROJO_PID; exit 1' SIGINT

if [[ -n "$COMMON_PID" ]]; then
    wait $COMMON_PID $PLACE_PID $ROJO_PID
else
    wait $PLACE_PID $ROJO_PID
fi

print_done "Compilation and Rojo serve complete."
