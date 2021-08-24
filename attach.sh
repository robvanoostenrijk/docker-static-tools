#!/bin/bash

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

docker exec -it $1 /tools/tools.sh
