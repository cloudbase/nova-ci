exec_with_retry2 () {
    MAX_RETRIES=$1
    INTERVAL=$2

    COUNTER=0
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

exec_with_retry () {
    CMD=$1
    MAX_RETRIES=${2-10}
    INTERVAL=${3-0}

    exec_with_retry2 $MAX_RETRIES $INTERVAL $CMD
}

run_wsmancmd_with_retry () {
    HOST=$1
    USERNAME=$2
    PASSWORD=$3
    CMD=$4

    exec_with_retry "python /home/jenkins-slave/tools/wsman.py -U https://$HOST:5986/wsman -u $USERNAME -p $PASSWORD $CMD"
}

wait_for_listening_port () {
    HOST=$1
    PORT=$2
    TIMEOUT=$3
    exec_with_retry "nc -z -w$TIMEOUT $HOST $PORT" 100 5
}

run_ssh_cmd () {
    SSHUSER_HOST=$1
    SSHKEY=$2
    CMD=$3
    ssh -t -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -i $SSHKEY $SSHUSER_HOST "$CMD"
}

run_ssh_cmd_with_retry () {
    SSHUSER_HOST=$1
    SSHKEY=$2
    CMD=$3
    INTERVAL=$4
    MAX_RETRIES=10

    COUNTER=0
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

join_hyperv (){
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned Remove-Item -Recurse -Force C:\OpenStack\nova-ci ; git clone https://github.com/cloudbase/nova-ci C:\OpenStack\nova-ci ; cd C:\OpenStack\nova-ci ; git checkout cambridge >>\\'$FIXED_IP'\openstack\logs\create-environment-'$1'.log 2>&1'
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\teardown.ps1'
    [ "$IS_DEBUG_JOB" == "yes" ] && run_wsmancmd_with_retry $1 $2 $3 '"powershell Write-Host Calling gerrit with zuul-site='$ZUUL_SITE' gerrit-site='$ZUUL_SITE' zuul-ref='$ZUUL_REF' zuul-change='$ZUUL_CHANGE' zuul-project='$ZUUL_PROJECT' >>\\'$FIXED_IP'\openstack\logs\create-environment-'$1'.log 2>&1"'
    run_wsmancmd_with_retry $1 $2 $3 '"bash C:\OpenStack\nova-ci\HyperV\scripts\gerrit-git-prep.sh --zuul-site '$ZUUL_SITE' --gerrit-site '$ZUUL_SITE' --zuul-ref '$ZUUL_REF' --zuul-change '$ZUUL_CHANGE' --zuul-project '$ZUUL_PROJECT' >>\\'$FIXED_IP'\openstack\logs\create-environment-'$1'.log 2>&1"'
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\EnsureOpenStackServices.ps1 Administrator H@rd24G3t >>\\'$FIXED_IP'\openstack\logs\create-environment-'$1'.log 2>&1'
    [ "$IS_DEBUG_JOB" == "yes" ] && run_wsmancmd_with_retry $1 $2 $3 '"powershell Write-Host Calling create-environment with devstackIP='$FIXED_IP' branchName='$ZUUL_BRANCH' buildFor='$ZUUL_PROJECT' '$IS_DEBUG_JOB' >>\\'$FIXED_IP'\openstack\logs\create-environment-'$1'.log 2>&1"'
    run_wsmancmd_with_retry $1 $2 $3 '"powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\create-environment.ps1 -devstackIP '$FIXED_IP' -branchName '$ZUUL_BRANCH' -buildFor '$ZUUL_PROJECT' '$IS_DEBUG_JOB' >>\\'$FIXED_IP'\openstack\logs\create-environment-'$1'.log 2>&1"'
}

teardown_hyperv () {
    run_wsmancmd_with_retry $1 $2 $3 'powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\teardown.ps1'
}

post_build_restart_hyperv_services (){
    run_wsmancmd_with_retry $1 $2 $3 '"powershell -ExecutionPolicy RemoteSigned C:\OpenStack\nova-ci\HyperV\scripts\post-build-restart-services.ps1 >>\\'$FIXED_IP'\openstack\logs\create-environment-'$1'.log 2>&1"'
}

poll_shh () {
	IP=$1

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
