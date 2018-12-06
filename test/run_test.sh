#!/bin/bash
TS_TMPDIR=
TS_QUEUE_RESULT=
TS_EXIT_CODE=0
TS_LOG_DEBUG=false
TS_TEST_DIR=
TS_DISPLAY_TEST_LOG=true
TS_DISPLAY_TEST_RESULT=true
TS_SYNC_TEST=false
TS_TEST_TO_RUN=

help() {
    cat <<EOF
$0 [-d][-q][-Q][-s][-o <test_filename>] <test_dir>

Help:
-d debug log
-h display this message
-q quiet tests log
-Q quiet tests result
-s run test in a sync way
-t specify one test filename to run. This file should be in <test_dir>
EOF
    exit 0
}

# Check if all needed environment variable are set
check_env() {
    while getopts ":dhqQst:" option
    do
        case $option in
            d)
                TS_LOG_DEBUG=true
            ;;
            h)
                help
            ;;
            q)
                TS_DISPLAY_TEST_LOG=false
            ;;
            Q)
                TS_DISPLAY_TEST_RESULT=false
            ;;
            s)
                TS_SYNC_TEST=true
            ;;
            t)
                TS_TEST_TO_RUN=$OPTARG
            ;;
            :)
                echo "Arg required for $OPTARG"
                exit 1
            ;;
            \?)
                echo "Invalid option: $OPTARG"
                echo
                help
            ;;
        esac
    done
    
    # First args after option should be the TS_TEST_DIR
    shift $((OPTIND-1))
    TS_TEST_DIR=$1
    if [[ -z $TS_TEST_DIR ]];then
        echo "Test directory not provided"
        help
    fi
    if [[ ! -d $TS_TEST_DIR ]];then
        die "Test directory $TS_TEST_DIR not found"
    fi
    
    # Check test files are OK
    get_test_files > /dev/null
}

# Log
log_error() {
    echo "ERROR: $@" >&2
}

die() {
    log_error $@
    exit 1
}

log_debug() {
    [[ $TS_LOG_DEBUG == true ]] || return
    echo "DEBUG: $@"
}

# This will enable log with prefix string, this method should be used in a subshell
enable_prefix_log() {
    local prefix=$1
    exec > >(awk '$0="['$prefix'][INFO]\t"$0') 2> >(awk '$0="['$prefix'][ERROR]\t"$0' >&2)
}
# reset stdout/stderr to &1 &2
reset_log() {
    # restor previsously saved fd
    exec 1>&6 2>&7
}

# Disable all output (stdout & stderr)
disable_log() {
    exec >/dev/null 2>/dev/null
}

# This will create all file/queue needed by this test framework
prepare_system() {
    TS_TMPDIR=$(mktemp -d)
    TS_QUEUE_RESULT=$TS_TMPDIR/result
    touch $TS_QUEUE_RESULT
    log_debug "tmp dir: $TS_QUEUE_RESULT"
    
    # save filedescriptor
    exec 6>&1 # save stdout in 6
    exec 7>&2 # save stderr in 7
}

# Remove all file/queue created by this test framework and exit with $TS_EXIT_CODE
shutdown_system() {
    log_debug "shutdown framework"
    rm -rf $TS_TMPDIR
}

# Get all test files that need to be exec
get_test_files() {
    if [[ ! -z $TS_TEST_TO_RUN ]]; then
        local test_file=$TS_TEST_DIR/$TS_TEST_TO_RUN
        [[ -e $test_file ]] || die "Test file not found: $test_file"
        echo $test_file
        return
    fi
    
    test_files=$(ls $TS_TEST_DIR/test_*)
    if [[ -z "$test_files" ]]; then
     die "No test file found in $TS_TEST_DIR"
    fi
    echo "$test_files"
}

# Send test result in queue
send_test_result() {
    local test_name=$1
    local test_exit_code=$2
    echo "$2|$1" >> $TS_QUEUE_RESULT
}

# Get exist code from result string
get_exit_code_from_result(){
    local result=$1
    echo $result | awk -F'|' '{ print $1}'
}

# Get test name from result string
get_test_name_from_result(){
    local result=$1
    echo $result | awk -F'|' '{ print $2}'
}

# Run a single test
run_test(){
    local test_file=$1
    
    local test_name=$(basename $test_file)
    if [[ $TS_DISPLAY_TEST_LOG == "true" ]];then
        reset_log
        enable_prefix_log $test_name
    else
        disable_log
    fi
    
    # exec script
    if [[ -z "$TS_REMOTE_PREFIX_COMMAND" ]]; then
        $test_file
    else
        cat $test_file | $TS_REMOTE_PREFIX_COMMAND
    fi
    
    # send result to the queue
    send_test_result "$test_name" $?
}

# Source setup.sh file
source_setup(){
    # source setup.sh before exec test
    if [ -e $TS_TEST_DIR/setup.sh ]; then
        log_debug 'source setup.sh'
        
        if [[ $TS_DISPLAY_TEST_LOG == "true" ]];then
            enable_prefix_log "setup.sh"
        else
            disable_log
        fi
        source $TS_TEST_DIR/setup.sh
        local return_code=$?
        reset_log
        log_debug 'source setup.sh done'
    fi
    return $return_code
}

run_teardown(){
    if [ -e $TS_TEST_DIR/teardown.sh ]; then
        log_debug 'exec teardown.sh'
        
        if [[ $TS_DISPLAY_TEST_LOG == "true" ]];then
            enable_prefix_log "teardown.sh"
        else
            disable_log
        fi
        $TS_TEST_DIR/teardown.sh
        local return_code=$?
        reset_log
        log_debug 'exec teardown.sh done'
    fi
    return $return_code
}

# Run all tests
run_tests() {

    # This subshell is used to jail all vars that can be define by test files
    (
        source_setup || die "Source error"
        
        for test_file in $(get_test_files); do
            (
                if [[ $TS_SYNC_TEST == "true" ]]; then
                    run_test $test_file
                else
                    run_test $test_file&
                fi
            )
        done
        
        wait_test
        run_teardown
    )
}

# Listen queue
wait_test(){
    local NB_TEST=$(get_test_files | wc -l | sed 's/[^0-9]*//g')
    local i=0

    # Wait and concat all test result
    while read line
    do
        ((i++))
        log_debug "DONE?" $i $NB_TEST
        if [[ $i == $NB_TEST ]]; then
            # No more test
            break
        fi
        
    done < <(tail -f -n $NB_TEST $TS_QUEUE_RESULT)
    log_debug "Test should be finished"
}

compile_test_result() {
    # Display result
    (
        [[ $TS_DISPLAY_TEST_RESULT == "true" ]] || disable_log
        
        echo "## Result ##"
         while read result; do
            local test_status=" \e[32mPASS\e[39m"
            if [[ $(get_exit_code_from_result $result)  != 0 ]]; then
                test_status="\e[31mFAIL\e[39m"
                # If at least one test fail exit code should be >= 1
                exit_code=1
            fi
            echo -e $test_status $(get_test_name_from_result $result)
        done < $TS_QUEUE_RESULT
        return $exit_code
    )
    TS_EXIT_CODE=$?
}

# Run framework
check_env $@
prepare_system
trap shutdown_system EXIT
run_tests

compile_test_result

exit $TS_EXIT_CODE