function exec_with_retry2 () {
    local MAX_RETRIES=$1
    local INTERVAL=$2
    local COUNTER=0

    while [ $COUNTER -lt $MAX_RETRIES ]; do
        EXIT=0
        echo `date -u +%H:%M:%S`
        eval '${@:3}' || EXIT=$?
        if [ $EXIT -eq 0 ]; then
            return 0
        fi
        let COUNTER=COUNTER+1

        if [ -n "$INTERVAL" ]; then
            sleep $INTERVAL
        fi
    done
    return $EXIT
}

function exec_with_retry () {
    local CMD=$1
    local MAX_RETRIES=${2-10}
    local INTERVAL=${3-0}

    exec_with_retry2 $MAX_RETRIES $INTERVAL $CMD
}

function run_wsmancmd_with_retry () {
    local HOST=$1
    local USERNAME=$2
    local PASSWORD=$3
    local CMD=$4

    exec_with_retry "python /home/jenkins-slave/tools/wsman.py -U https://$HOST:5986/wsman -u $USERNAME -p $PASSWORD $CMD"
}

function run_wsman_cmd() {
    local host=$1
    local win_user=$2
    local win_password=$3
    local cmd=$4

    python /home/jenkins-slave/tools/wsman.py -u $win_user -p $win_password -U https://$host:5986/wsman $cmd
}

function run_wsman_ps() {
    local host=$1
    local win_user=$2
    local win_password=$3
    local cmd=$4

    run_wsman_cmd $host $win_user $win_password "powershell -NonInteractive -ExecutionPolicy RemoteSigned -Command $cmd"
}

function wait_for_listening_port () {
    local HOST=$1
    local PORT=$2
    local TIMEOUT=$3

    exec_with_retry "nc -z -w$TIMEOUT $HOST $PORT" 15 4
}

function run_ssh_cmd () {
    local SSHUSER_HOST=$1
    local SSHKEY=$2
    local CMD=$3

    ssh -t -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i $SSHKEY $SSHUSER_HOST "$CMD"
}

function run_ssh_cmd_with_retry () {
    local SSHUSER_HOST=$1
    local SSHKEY=$2
    local CMD=$3
    local INTERVAL=$4
    local MAX_RETRIES=10
    local COUNTER=0

    while [ $COUNTER -lt $MAX_RETRIES ]; do
        EXIT=0
        run_ssh_cmd $SSHUSER_HOST $SSHKEY "$CMD" || EXIT=$?
        if [ $EXIT -eq 0 ]; then
            return 0
        fi
        let COUNTER=COUNTER+1

        if [ -n "$INTERVAL" ]; then
            sleep $INTERVAL
        fi
    done
    return $EXIT
}

function join_hyperv (){
    run_wsmancmd_with_retry $1 $2 $3 'powershell if (-Not (test-path '$LOG_DIR')){mkdir '$LOG_DIR'} ; if (-Not (test-path '$BUILD_DIR')){mkdir '$BUILD_DIR'}'
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned Remove-Item -Recurse -Force C:\OpenStack\nova-ci ; git clone https://github.com/andreibacos/hetzner-nova-ci C:\OpenStack\nova-ci ; cd C:\OpenStack\nova-ci >> '$LOG_DIR'\create-environment.log 2>&1'
#    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\teardown.ps1'
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned pip install zuul==2.5.2'
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned zuul-cloner -m C:\OpenStack\nova-ci\jobs\clonemap.yaml -v git://git.openstack.org '$ZUUL_PROJECT' --zuul-branch '$ZUUL_BRANCH' --zuul-ref '$ZUUL_REF' --zuul-url '$ZUUL_SITE'/p --workspace c:\openstack\build'

    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\EnsureOpenStackServices.ps1 '$2' '$3' >> '$LOG_DIR'\create-environment.log 2>&1'
    [ "$IS_DEBUG_JOB" == "yes" ] && run_wsmancmd_with_retry $1 $2 $3 '"powershell Write-Host Calling create-environment with devstackIP='$DEVSTACK_IP' branchName='$ZUUL_BRANCH' buildFor='$ZUUL_PROJECT' zuulChange='$ZUUL_CHANGE' '$IS_DEBUG_JOB' >> '$LOG_DIR'\create-environment.log 2>&1"'
    run_wsmancmd_with_retry $1 $2 $3 '"powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\create-environment.ps1 -devstackIP '$DEVSTACK_IP' -branchName '$ZUUL_BRANCH' -buildFor '$ZUUL_PROJECT' -zuulChange '$ZUUL_CHANGE' '$IS_DEBUG_JOB' >> '$LOG_DIR'\create-environment.log 2>&1"'
}

function teardown_hyperv () {
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\teardown.ps1'
}

function post_build_restart_hyperv_services (){
    LOG_DIR='C:\Openstack\logs\'
    run_wsmancmd_with_retry $1 $2 $3 '"powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\post-build-restart-services.ps1 >> '$LOG_DIR'\create-environment.log 2>&1"'
}

function poll_shh () {
	local IP=$1

	if [ -z "$IP" ]
	then
	    echo "Missing IP address"
	    exit 1
	fi

	count=0

	function try_port() {

	    while true
	    do
	        # we sleep from the beginning. Devstack has just been spun up
	        # unless it resumes from ram, it will not be up instantly
	        sleep 5
	        nc -w 3 -z "$1" "$2" > /dev/null 2>&1 && break
	        count=$(($count + 1))
	        if [ $count -eq 24 ]
	        then
	            return 1
	        fi
	    done
	    return 0
	}

	try_port $IP 22
}

