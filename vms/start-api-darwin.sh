#!/usr/bin/env bash
set -euo pipefail

export NAME="api-vm"
export LISTEN_ADDR="127.0.0.1:80"

./$(dirname "$0")/../bin/api/api-darwin

