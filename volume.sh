#!/bin/bash

print_help () {
	echo "[i] Usage: $0 container-name docker-image-ref [optional-docker-cmd]"
	exit
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	print_help
fi

if [[ -z "$1" || -z "$2" ]]; then
	print_help
fi

docker volume create static-tools

echo "-- VOLUME --"
docker run --rm -v static-tools:/volume static-tools /volume/

echo "-- CONTAINER --"

# Run a container with the volume mounted in /tools
docker \
	run --rm -ti \
	-v static-tools:/tools \
	--name $1 \
	$2 $3
#
# Remove the created volume
docker volume rm static-tools
