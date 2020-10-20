#!/usr/bin/env bash
set -euo pipefail

export NAME="web"
export LISTEN_ADDR="0.0.0.0:8080"

export UPSTREAM_URIS="http://api"

./$(dirname "$0")/../bin/web/web-darwin
