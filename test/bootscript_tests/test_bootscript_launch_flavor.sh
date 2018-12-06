#!/bin/bash

# This test will try to boot an image on different flavors

initialize_vars

IMAGE_ID=${IMAGE_IDS[0]}
for FLAVOR in $FLAVORS; do
    echo "run_vm $IMAGE_ID $FLAVOR $BOOTSCRIPT_ID"
done |  xargs -P$MAX_PARALLEL_VM -I %% bash -c '{ sleep $((RANDOM%5)); %% ; }'
