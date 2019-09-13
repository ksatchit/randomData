#!/bin/bash

METRICS_GIT_URL=${METRICS_GIT_URL:=https://gitlab.com/litmuschaos/demo-app.git}
METRICS_GIT_BRANCH=${METRICS_GIT_BRANCH:=exporter}
POLLING_INTERVAL=${POLLING_INTERVAL:=5}

echo "METRICS REPO: ${METRICS_GIT_URL}"
echo "METRICS BRANCH: ${METRICS_GIT_BRANCH}" 

git init 
git remote add origin ${METRICS_GIT_URL}

echo "METRICS PULL INTERVAL: ${POLLING_INTERVAL}"

while true
do
  echo -e "\nPulling metrics @ $(date)"
  echo "************************************************"
  git pull origin ${METRICS_GIT_BRANCH}  
  echo "************************************************"
  sleep ${POLLING_INTERVAL}
done 
