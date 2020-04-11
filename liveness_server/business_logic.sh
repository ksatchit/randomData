#!/bin/sh

# Stores status in a action.status file
function updateStatus(){
    status=$1 
    echo "status is: ${status}"
    echo ${status} > /var/tmp/action.status
}

interval=${LIVENESS_PERIOD_SECONDS:-10}
echo "This is the business logic script"

## Start of business logic, executed as several continuous cycles
while true; do 
    ## Cycle 1..n
    updateStatus CycleInprogress;
    sleep 2 ## dummy liveness business logic
    updateStatus CycleComplete;
    sleep ${interval}
done 
