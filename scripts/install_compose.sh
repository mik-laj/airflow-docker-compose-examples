#!/usr/bin/env bash

set -euo pipefail

if command -v docker-compose &>/dev/null; then
    COMPOSE_BIN="$(command -v docker-compose)"
else
    COMPOSE_BIN="$(echo "$PATH" | cut -d ":" -f 1)/docker-compose"
fi

echo "COMPOSE_BIN=${COMPOSE_BIN}"

[[ $# -ne 1 ]] && (echo "Missing required argument - VERSION."; exit 1)

TARGET_VERSION=${1}

if [[ -f "${COMPOSE_BIN}" ]]; then
    echo "Found existing docker-compose. Uninstalling."
    sudo rm -rf "${COMPOSE_BIN}"
fi
if [[ "${TARGET_VERSION}" == "latest" ]]; then
    URL=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.assets[].browser_download_url | select(endswith("docker-compose-linux-x86_64"))')
    curl --fail -L "$URL" -o docker-compose
    chmod +x docker-compose
    sudo mv docker-compose "${COMPOSE_BIN}"
    echo "Installed docker-compose v2 (latest)"
elif [[ "${TARGET_VERSION}" = 2.* ]]; then
    echo "Install docker-compose v2: ${TARGET_VERSION}"
    URL=$(curl 'https://api.github.com/repos/docker/compose/releases' | \
        jq '.[] | select(.name = ("v" + $ver))' --arg "ver" "${TARGET_VERSION}" | \
        jq -r '.assets[].browser_download_url | select(endswith("docker-compose-linux-x86_64"))')
    curl --fail -L "$URL" -o docker-compose
    chmod +x docker-compose
    sudo mv docker-compose "${COMPOSE_BIN}"
    echo "Installed docker-compose v${TARGET_VERSION}"
elif [[ "${TARGET_VERSION}" = 1.* ]]; then
    echo "Install docker-compose v1: ${TARGET_VERSION}"
    curl -fsSL "https://github.com/docker/compose/releases/download/${TARGET_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o docker-compose
    chmod +x docker-compose
    sudo mv docker-compose "${COMPOSE_BIN}"
    echo "Installed docker-compose v1"
else
    echo "Unsupported version: ${TARGET_VERSION}"
    exit 1
fi

docker-compose -v || docker-compose version || docker-compose
