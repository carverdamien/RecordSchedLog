#!/bin/bash
set -e -x -u
TAR="$1"
SRC_DIR=/home/redha/RecordSchedLog/output/
DSTS="damien@w2155.rsr.lip6.fr:/home/damien/git/carverdamien/trace-cmd/TraceDisplay/examples/trace/"
for DST in ${DSTS}
do
    rsync -e "ssh -i /home/damien/.ssh/id_rsa" --size-only -rvP "${SRC_DIR}" "${DST}"
done
if [ -x ./host/${HOSTNAME}/notify ]
then
    ./host/${HOSTNAME}/notify "New Record: ${TAR}"
fi
