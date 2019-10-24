#!/bin/bash
set -e -x -u
TAR="$1"
SRC_DIR=/home/redha/RecordSchedLog/output/
DSTS="redha@i44.rsr.lip6.fr:/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/redha/"
for DST in ${DSTS}
do
    rsync -e "ssh -i /home/redha/.ssh/id_rsa" --size-only -rvP "${SRC_DIR}" "${DST}"
done
if [ -x ./host/${HOSTNAME}/notify ]
then
    ./host/${HOSTNAME}/notify "New Record: [redha] ${TAR}"
fi
