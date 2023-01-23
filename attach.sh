#!/bin/bash

IMAGE_REF=ghcr.io/robvanoostenrijk/docker-static-tools:latest

print_help () {
	echo "[i] Usage: $0 container-name [local-container]"
	exit
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	print_help
fi

if [[ -z "$1" ]]; then
	print_help
fi

if ! [[ -z "$2" ]]; then
	echo "[i] Using local image reference $2"
	IMAGE_REF=$2
fi

CONTAINER=$(docker create ${IMAGE_REF})
echo "[i] Created container ${CONTAINER:0:12}"

echo "[i] Inject static tools"
docker cp "${CONTAINER}:/tools" - | docker cp - "${1}:/"

echo "[i] Removing container ${CONTAINER:0:12}"
docker rm $CONTAINER > /dev/null

docker exec -ti $1 /tools/entrypoint.sh
