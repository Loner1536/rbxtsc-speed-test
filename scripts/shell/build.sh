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

mkdir -p "dist/out"

# 📁 Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."

SOURCES_DIR="$ROOT_DIR/sources"
PLACES_DIR="$ROOT_DIR/places"
COMMON_TSCONFIG="$ROOT_DIR/common.tsconfig.json"
PLACE_TSCONFIG="$ROOT_DIR/$PLACE.tsconfig.json"
COMMON_PROJECT="$ROOT_DIR/common.project.json"
PLACE_PROJECT="$ROOT_DIR/$PLACE.project.json"

INCLUDE_DIR="$ROOT_DIR/dist/include"

# Check package.json presence at root
if [ ! -f "$ROOT_DIR/package.json" ]; then
    print_error "package.json not found in root ($ROOT_DIR)"
    exit 1
fi

print_step "🧹 Cleaning build files and old configs..."

# Remove all *.tsconfig.json except tsconfig.json
find "$ROOT_DIR" -maxdepth 1 -type f -name "*.tsconfig.json" ! -name "tsconfig.json" -exec rm -f {} \;

# Remove all *.project.json files in root (assuming only root contains them)
find "$ROOT_DIR" -maxdepth 1 -type f -name "*.project.json" -exec rm -f {} \;

# Remove all *.tsbuildinfo files anywhere under dist/out/
find "$ROOT_DIR/dist/out" -type f -name "*.tsbuildinfo" -exec rm -f {} \;

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

print_step "🚀 Compiling TypeScript..."

if [[ "$INCLUDE_COMMON" == "true" ]]; then
    npx rbxtsc -p "$COMMON_TSCONFIG" --rojo "$COMMON_PROJECT" -i "$INCLUDE_DIR"
    print_done "Common compiled."
fi

npx rbxtsc -p "$PLACE_TSCONFIG" --rojo "$PLACE_PROJECT" -i "$INCLUDE_DIR"
print_done "'$PLACE' compiled."

print_step "📦 Building .rbxlx file with Rojo..."

mkdir -p "$PLACES_DIR" # Ensure places folder exists

ROJO_OUTPUT="$PLACES_DIR/$PLACE.rbxlx" # Build into places folder
rojo build "$PLACE_PROJECT" -o "$ROJO_OUTPUT"

print_done ".rbxlx build complete: $ROJO_OUTPUT"
