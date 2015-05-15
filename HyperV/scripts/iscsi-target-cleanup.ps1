$rawPersistentTargets = iscsicli ListPersistentTargets

function getValue($mapping){
    return $mapping.split(':')[1].Trim(' ')
}

foreach($line in $rawPersistentTargets){
    if ($line.Contains("Target Name")){
        $targetName = ($line.split(':')[1] + ":" + $line.split(':')[2]).Trim(' ')
    }
    if ($line.Contains("Address and Socket")){
        $addrAndSocket = getValue($line)
    }
    if ($line.Contains("Initiator Name")){
        $initiatorName = getValue($line)
    }
    if ($line.Contains("Port Number")){
        $initiatorPort = getValue($line)
        if ($initiatorPort.Contains("Any Port")){
            $initiatorPort = '*'
        }
        echo "Removing persistent target $targetName"
    	iscsicli.exe RemovePersistentTarget $initiatorName $targetName $initiatorPort $addrAndSocket.Split(' ')
    }
}
