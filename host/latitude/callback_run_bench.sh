#!/bin/bash
set -e -x -u
TAR="$1"
SRC_DIR=/home/dc/git/carverdamien/RecordSchedLog/output/
DSTS="damien@i44.rsr.lip6.fr:/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/" # "damien@amd48b-systeme.rsr.lip6.fr:/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/"
for DST in ${DSTS}
do
    rsync -e "ssh -i /home/dc/.ssh/id_rsa" --size-only -rvP "${SRC_DIR}" "${DST}"
done
if [ -x ./host/${HOSTNAME}/notify ]
then
    ./host/${HOSTNAME}/notify "New Record: ${TAR}"
fi
