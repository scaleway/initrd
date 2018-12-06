export MAX_PARALLEL_VM=6
export MAX_PARALLEL_VM="${MAX_PARALLEL_VM:-6}"

if [[ -z $BOOTSCRIPT_ID ]]; then
    echo "BOOTSCRIPT_ID is not defined"
    exit 1
fi

if [[ -z $ARCH ]]; then
    echo "ARCH is not defined"
    exit 1
fi


initialize_vars(){
    # initialize_vars is a function instead of exported var because
    # at this time we can't export array in bash

    IMAGE_IDS=() # Define empty array
    IMAGE_IDS+=( "265b32a3" ) #Ubuntu_Xenial  [arm arm64 x86_64]
    IMAGE_IDS+=( "944a4410" ) #Ubuntu_Bionic  [arm arm64 x86_64]
    IMAGE_IDS+=( "7300a842" ) #Debian_Stretch [arm arm64 x86_64]

    if [[ $ARCH == "arm" ]]; then
        FLAVORS=( "C1" )

        IMAGE_IDS+=( "24d33e48" ) #CentOS_7_2     [arm]
        IMAGE_IDS+=( "f6db6d8e" ) #Gentoo         [arm]
        IMAGE_IDS+=( "f2795e5e" ) #openSUSE       [arm]
    elif [[ $ARCH == "arm64" ]]; then
        FLAVORS=( "ARM64-2GB" )

        IMAGE_IDS+=( "1398b772" ) #CentOS_7_3     [arm64]
    elif [[ $ARCH == "x86_64" ]]; then
        FLAVORS=( "START1-S" "C2S" )

        IMAGE_IDS+=( "49e33199" ) #Fedora_28      [x86_64]
        IMAGE_IDS+=( "39d6dad1" ) #CentOS_7_4     [x86_64]
        IMAGE_IDS+=( "f7696517" ) #Arch_Linux     [x86_64]
        IMAGE_IDS+=( "be2293b6" ) #Alpine_Linux   [x86_64]
    fi
}

vm_exec_true(){
    local INSTANCE_ID=$1
    while true; do
        scw exec $INSTANCE_ID true 2>/dev/null && return 0
        sleep 2
    done
}

run_vm(){
    local IMAGE_ID=$1
    local FLAVOR=$2
    local BOOTSCRIPT_ID=$3
    echo "Test $IMAGE_ID with bootscript $BOOTSCRIPT_ID on $FLAVOR"
    
    INSTANCE_ID=$(scw create --boot-type=bootscript --bootscript=$BOOTSCRIPT_ID --name test-bootscript --commercial-type=$FLAVOR $IMAGE_ID)
    if [[ "$?" != 0 ]]; then
        echo "Error on creation $FLAVOR with image $IMAGE_ID"
        exit 1
    fi

    # remove instance at the end of this function
    trap "scw rm -f $INSTANCE_ID > /dev/null" RETURN

    # start instance and try to exec a command
    scw start $INSTANCE_ID > /dev/null
    timeout 5m bash -c "vm_exec_true $INSTANCE_ID"
    RETURN_CODE=$?
    
    if [[ "$RETURN_CODE" != "0" ]]; then
        echo "ERROR on $FLAVOR with image $IMAGE_ID"
        return 1
    fi
    
    echo "OK on $FLAVOR with image $IMAGE_ID"
}

export -f run_vm
export -f vm_exec_true
export -f initialize_vars