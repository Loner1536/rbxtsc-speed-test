#!/bin/bash
set -euo pipefail

PLACE=$1

if [ -z "$PLACE" ]; then
    echo "Usage: $0 <place-name>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."

BASE_DIR="$ROOT_DIR/sources/base"
BASE_PROJECT="$BASE_DIR/base.project.json"
BASE_TSCONFIG="$BASE_DIR/base.tsconfig.json"

PLACE_DIR="$ROOT_DIR/sources/$PLACE"
PLACE_PROJECT="$PLACE_DIR/$PLACE.project.json"
PLACE_TSCONFIG="$PLACE_DIR/$PLACE.tsconfig.json"

check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ Required file not found: $1"
        exit 1
    fi
}

check_file "$ROOT_DIR/package.json"
check_file "$BASE_PROJECT"
check_file "$BASE_TSCONFIG"
check_file "$PLACE_PROJECT"
check_file "$PLACE_TSCONFIG"

cd "$ROOT_DIR"

# Symlink node_modules to both base and $PLACE
link_node_modules() {
    local dir=$1
    if [ -e "$dir/node_modules" ] && [ ! -L "$dir/node_modules" ]; then
        echo "⚠️ Removing existing node_modules in $dir"
        rm -rf "$dir/node_modules"
    fi
    if [ ! -L "$dir/node_modules" ]; then
        echo "🔗 Linking node_modules to $dir"
        ln -s "$ROOT_DIR/node_modules" "$dir/node_modules"
    fi
}
link_node_modules "$BASE_DIR"
link_node_modules "$PLACE_DIR"

echo "[1/5] 📦 Installing npm packages..."
npm install

echo "[2/5] 🔌 Installing Rokit packages..."
rokit install --no-trust-check

echo "[3/5] 🧹 Cleaning previous build files..."
rm -rf "$ROOT_DIR/out"

echo "[4/5] 🚀 Starting rbxtsc watch on base and $PLACE..."

# Run both in background
npx rbxtsc --watch --project "$BASE_TSCONFIG" --verbose &
BASE_PID=$!

npx rbxtsc --watch --rojo "$PLACE_PROJECT" --project "$PLACE_TSCONFIG" --verbose &
PLACE_PID=$!

# Wait for compilation of both by checking .tsbuildinfo files existence
echo "⏳ Waiting for initial compilation..."

until [ -f "$ROOT_DIR/out/base.tsbuildinfo" ] && [ -f "$ROOT_DIR/out/$PLACE.tsbuildinfo" ]; do
    sleep 1
done

echo "✅ Both compiled! Launching Rojo for $PLACE..."

rojo serve "$PLACE_PROJECT"

# Wait on both watchers
wait $BASE_PID
wait $PLACE_PID
