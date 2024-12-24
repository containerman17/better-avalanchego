#!/bin/bash

set -euo pipefail

AVALANCHEGO_DATA_DIR=${AVALANCHEGO_DATA_DIR:-$HOME/.avalanchego}

# Create plugins directory and copy plugins
mkdir -p "$AVALANCHEGO_DATA_DIR/plugins"
cp -r /plugins/* "$AVALANCHEGO_DATA_DIR/plugins/"

# Write BLS key if provided
if [ -n "${BLS_KEY_BASE64:-}" ]; then
    mkdir -p "$AVALANCHEGO_DATA_DIR/staking"
    echo "$BLS_KEY_BASE64" | base64 -d > "$AVALANCHEGO_DATA_DIR/staking/signer.key"
fi

# Function to convert ENV vars to flags
get_avalanchego_flags() {
    local flags=""
    while IFS= read -r line; do
        name="${line%%=*}"
        value="${line#*=}"
        if [[ $name == AVALANCHEGO_* ]]; then
            flag_name=$(echo "${name#AVALANCHEGO_}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
            flags+="--$flag_name=$value "
        fi
    done < <(env)
    echo "$flags"
}

EXTRA_FLAGS=$(get_avalanchego_flags)
echo "Extra flags: $EXTRA_FLAGS"

# Launch avalanchego with dynamic flags
/usr/local/bin/avalanchego $EXTRA_FLAGS
