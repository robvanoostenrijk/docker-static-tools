#!/bin/bash

IMAGE_REF=ghcr.io/robvanoostenrijk/docker-static-tools:latest

print_help () {
	echo "[i] Usage: $0 container-name"
	exit
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	print_help
fi

if [[ -z "$1" ]]; then
	print_help
fi


CONTAINER=$(docker create ${IMAGE_REF})
echo "[i] Created container ${CONTAINER:0:12}"

echo "[i] Inject static tools"
docker cp "${CONTAINER}:/tools" - | docker cp - "${1}:/"

echo "[i] Removing container ${CONTAINER:0:12}"
docker rm $CONTAINER > /dev/null

docker exec -ti $1 /tools/entrypoint.sh
