#!/bin/ash 
set -o nounset

: "${NC_CMD_ARGS:?Required environment variable NC_CMD_ARGS unset}"
if [ $? -eq 0 ] ; then 

  echo "cmd: /usr/bin/ncat ${NC_CMD_ARGS}" 
  /usr/bin/ncat ${NC_CMD_ARGS} | tee ${LOAD_PATH}/load.out


  #echo "cmd: /usr/bin/nc ${NC_CMD_ARGS}" 
  #/usr/bin/nc ${NC_CMD_ARGS} | tee ${LOAD_PATH}/load.out
fi 
