# RecordSchedLog

Tool to automate the followings:

1) build a custom kernel with SchedLog.
2) kexec reboot with specific options.
3) run bench.

`./RecordSchedLog.sh` looks for bench to run on host `${HOSTNAME}` in `./host/${HOSTNAME}/jobs/*.job.sh`.
If the kernel required for a job is not installed, it will be installed.
If machine is not running on the kernel required for a job, it will be rebooted.

## kbuild and kexec Steps

On host `${HOSTNAME}`, executing `./scripts/kbuild.sh host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}` builds and installs the kernel.

`host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}` is a directory that contains a kernel config (`config`) and a kernel source git submodule (`src`).

On host `${HOSTNAME}`, executing `./scripts/kbuild.sh host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION} host/${HOSTNAME}/cmdline/${APPEND}` reboots on ${KERNEL_LOCALVERSION} with the cmdline ${APPEND}.

`host/${HOSTNAME}/cmdline/${APPEND}` is a file that contains a cmdline.
