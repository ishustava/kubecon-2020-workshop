#!/usr/bin/env bash

# NOTE: http://api works thanks to /etc/hosts
# swap port between 9090 and 80 to hit VM and k8s respectively
export UPSTREAM_URIS="http://api:9090"
#export UPSTREAM_URIS="http://api:80"
export LISTEN_ADDR="0.0.0.0:8080"
export NAME="web"
export MESSAGE="web running on VM"

fake-service
