#!/usr/bin/env bash

kind create cluster --config "$(dirname "$0")/kind.yaml" --image 'kindest/node:v1.21.14'
