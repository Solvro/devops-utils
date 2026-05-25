#!/bin/bash
# This script is part of the Solvro/devops-utils project, licensed under the MIT license:
# https://github.com/Solvro/devops-utils
#
# Copyright (C) 2025 mini_bomba

set -euo pipefail

if [[ -z "$1" ]];
then
    cat >&2 <<EOF
Usage: inspect-pid <pid>

Finds which docker container the given PID is from and returns the output of 'docker inspect' for that container
EOF
    exit 1
fi

PID=$1

while [[ "$PID" -gt 1 ]];
do
    PROC_NAME="`grep '^Name:' "/proc/${PID}/status" | cut -f 2`"
    PROC_PPID="`grep '^PPid:' "/proc/${PID}/status" | cut -f 2`"

    if echo "$PROC_NAME" | grep -i "containerd-shim" >> /dev/null;
    then
        # this proc will have the container id in the cmdline
        # grep the NULL-separated cmdline for the -id param, and include next param as context,
        # then cut out only the second param
        CONTAINER_ID="`grep -z '^-id$' -A 1 "/proc/${PID}/cmdline" | cut -sf 2 -d ''`"
        if [[ -z "$CONTAINER_ID" ]]
        then
          echo "Failed to extract container ID from containerd-shim PID $PID" >&2
          exit 1
        fi
        docker inspect $CONTAINER_ID
        exit 0
    fi
    PID=$PROC_PPID
done

echo "PID $1 does not appear to be running under a docker container!" >&2
exit 1
