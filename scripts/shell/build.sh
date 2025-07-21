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

# 🧠 Arguments
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

# Check package.json presence at root
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

print_step "🚀 Compiling TypeScript..."

if [[ "$INCLUDE_BASE" == "true" ]]; then
    npx rbxtsc -p "$BASE_TSCONFIG" --rojo "$BASE_PROJECT" -i "$INCLUDE_DIR"
    print_done "Base compiled."
fi

npx rbxtsc -p "$PLACE_TSCONFIG" --rojo "$PLACE_PROJECT" -i "$INCLUDE_DIR"
print_done "'$PLACE' compiled."

print_step "📦 Building .rbxlx file with Rojo..."

ROJO_OUTPUT="$SOURCES_DIR/$PLACE/$PLACE.rbxlx"
rojo build "$PLACE_PROJECT" -o "$ROJO_OUTPUT"

print_done ".rbxlx build complete: $ROJO_OUTPUT"
