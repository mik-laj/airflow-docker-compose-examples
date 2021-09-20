#!/usr/bin/env bash

set -euo pipefail

function ver() {
  # convert SemVer number to comparable string (strips pre-release version)
  # shellcheck disable=SC2086,SC2183
  printf "%04d%04d%04d%.0s" ${1//[.-]/ }
}


if command -v docker-compose &>/dev/null; then
    COMPOSE_BIN="$(command -v docker-compose)"
else
    COMPOSE_BIN="$(echo $PATH | cut -d ":" -f 1)/docker-compose"
fi

echo "COMPOSE_BIN=${COMPOSE_BIN}"

[[ $# -ne 1 ]] && (echo "Missing required argument - VERSION."; exit 1)

TARGET_VERSION=${1}

(( $(ver ${TARGET_VERSION}) <= $(ver "1.0.0") )) && (echo "Unsupported version. Supported version - [1.0.0-2.0.0]"; exit 1)
(( $(ver ${TARGET_VERSION}) > $(ver "2.0.0")  )) && (echo "Unsupported version. Supported version - [1.0.0-2.0.0]"; exit 1)

if [[ -f "${COMPOSE_BIN}" ]]; then
    echo "Found existing docker-compose. Uninstalling."
    sudo rm -rf "${COMPOSE_BIN}"
fi
if (( $(ver ${TARGET_VERSION}) >= $(ver "2.0.0") )); then
    echo "Install docker-compose v2: ${TARGET_VERSION}"
    INSTALL_DIR="/opt/docker-compose-v2"
    mkdir -p "${INSTALL_DIR}"
    curl -fsSL "https://github.com/docker/compose-cli/releases/download/v2.0.0-beta.4/docker-compose-linux-amd64" -o "${INSTALL_DIR}/docker-compose-v2"
    chmod +x "${INSTALL_DIR}/docker-compose-v2"
    echo '#!/bin/bash' > "${COMPOSE_BIN}"
    echo "exec \"${INSTALL_DIR}/docker-compose-v2\" compose \"\${@}\"" > "${COMPOSE_BIN}"
    echo "${COMPOSE_BIN}"
    cat "${COMPOSE_BIN}"
    chmod +x "${COMPOSE_BIN}"
    echo "Installed docker-compose v2"
else
    echo "Install docker-compose v1: ${TARGET_VERSION}"
    curl -fsSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o docker-compose
    chmod +x docker-compose
    sudo mv docker-compose "${COMPOSE_BIN}"
fi
