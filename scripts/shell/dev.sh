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
    print_error "Usage: $0 <place-name> [include-base]"
    exit 1
fi

INCLUDE_BASE=${2:-}
if [ -z "$INCLUDE_BASE" ]; then
    if [ "$PLACE" = "base" ]; then
        INCLUDE_BASE="false"
    else
        INCLUDE_BASE="true"
    fi
fi

# 📁 Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."

SOURCES_DIR="$ROOT_DIR/sources"
BASE_TSCONFIG="$ROOT_DIR/base.tsconfig.json"
PLACE_TSCONFIG="$ROOT_DIR/$PLACE.tsconfig.json"
BASE_PROJECT="$ROOT_DIR/base.project.json"
PLACE_PROJECT="$ROOT_DIR/$PLACE.project.json"

OUTPUT_DIR="$ROOT_DIR/dist/out"
INCLUDE_DIR="$ROOT_DIR/dist/include"

# Validate project
if [ ! -f "$ROOT_DIR/package.json" ]; then
    print_error "package.json not found in root ($ROOT_DIR)"
    exit 1
fi

print_step "🧹 Cleaning build files and old configs..."

rm -f "$OUTPUT_DIR/base.tsbuildinfo" "$OUTPUT_DIR/$PLACE.tsbuildinfo"
rm -f "$BASE_TSCONFIG" "$PLACE_TSCONFIG" "$BASE_PROJECT" "$PLACE_PROJECT"
rm -rf "$INCLUDE_DIR" "$OUTPUT_DIR/base" "$OUTPUT_DIR/$PLACE"

print_done "Clean complete."

print_step "📦 Installing npm dependencies (root)..."
npm install --prefix "$ROOT_DIR"
print_done "npm install complete."

print_step "⚙️ Generating Rojo Trees and TS Configs..."

node "$ROOT_DIR/scripts/java/genRojoTree.js" base false
node "$ROOT_DIR/scripts/java/genRojoTree.js" "$PLACE" "$INCLUDE_BASE"

node "$ROOT_DIR/scripts/java/genTSConfig.js" base
node "$ROOT_DIR/scripts/java/genTSConfig.js" "$PLACE"

print_done "Generated Rojo Trees and TS Configs."

print_step "🚀 Starting TypeScript compilation in watch mode..."

if [[ "$INCLUDE_BASE" == "true" ]]; then
    npx rbxtsc -w -p "$BASE_TSCONFIG" --rojo "$BASE_PROJECT" -i "$INCLUDE_DIR" &
    BASE_PID=$!
else
    BASE_PID=""
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
    # Optional: kill started processes before exiting
    [[ -n "$BASE_PID" ]] && kill $BASE_PID || true
    kill $PLACE_PID || true
    exit 1
fi

print_done "Output exists: $EXPECTED_PATH"

print_step "🛠️  Starting Rojo server..."
rojo serve "$PLACE_PROJECT" &
ROJO_PID=$!

# Graceful shutdown
trap 'echo -e "\n${YELLOW}⚠️ Interrupt received, stopping processes...${RESET}"; [[ -n "$BASE_PID" ]] && kill $BASE_PID; kill $PLACE_PID; kill $ROJO_PID; exit 1' SIGINT

if [[ -n "$BASE_PID" ]]; then
    wait $BASE_PID $PLACE_PID $ROJO_PID
else
    wait $PLACE_PID $ROJO_PID
fi

print_done "Compilation and Rojo serve complete."
