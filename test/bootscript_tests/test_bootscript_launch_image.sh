#!/bin/bash

# This test will try to boot differents images on a specific flavor

initialize_vars

FLAVOR=${FLAVORS[0]}

for IMAGE_ID in ${IMAGE_IDS[@]}; do
    echo "run_vm $IMAGE_ID $FLAVOR $BOOTSCRIPT_ID"
done |  xargs -P$MAX_PARALLEL_VM -I %% bash -c '{ sleep $((RANDOM%5)); %% ; }'
