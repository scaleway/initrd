einfo "Building from qcow2 image"

qcow2_disk_img=/tmp/disk.qcow2
volume=$(get_any volume "/dev/vda")
disk_img_url=$(get_any disk_img_url)
[ -z "$disk_img_url" ] && die "No url to get the disk image provided"

pre_build() {
    einfo "Retrieving disk image"
    run --abort curl -fksSL -o $qcow2_disk_img "$disk_img_url"
}

build() {
    einfo "Transferring image to volume"

    run --abort qemu-img convert -O raw $qcow2_disk_img $volume
    run --abort sgdisk -e $volume
    devinfo=$(sfdisk -d $volume 2>/dev/null)
    if [ $? -eq 0 ]; then
        devinfo=$(echo "$devinfo" | tr -d ' ')
        part_to_extend=""
        max_part_start=0
        header=true
        while read line; do
            if [ -z "$line" ]; then
                header=false
                continue
            elif ! $header; then
                IFS=':' read part params << EOF
$line
EOF
                IFS=','
                for param in $params; do
                    IFS='=' read key value << EOF
$param
EOF
                    if [ "$key" = "start" ]; then
                        if  [ "$value" -gt "$max_part_start" ]; then
                            max_part_start=$value
                            part_to_extend=$part
                        fi
                    elif [ "$key" = "uuid" -a "$part" = "$part_to_extend" ]; then
                        part_to_extend_uuid="$value"
                    fi
                done << EOF
$params
EOF
            fi
        done << EOF
$devinfo
EOF
        einfo "Extending last partition $part_to_extend to end of volume"
        part_number=$(echo "$part_to_extend" | sed "s-${volume}--")
        run --abort sgdisk -d $part_number -N $part_number -u $part_number:$part_to_extend_uuid $volume
    else
        einfo "No partition table detected, volume will be raw"
    fi
}

post_build() {
    devlayout=$(sgdisk -p $volume)
    if [ $? -eq 0 ]; then
        einfo "Final volume layout:"
        echo "$devlayout"
    fi
}
