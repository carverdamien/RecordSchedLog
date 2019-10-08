# RecordSchedLog

Tool to automate the following steps:

1) build a custom kernel with SchedLog.
2) kexec reboot with specific options.
3) run bench.

## Step 1) kbuild

On host `${HOSTNAME}`, executing `./kbuild.sh host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}` builds and installs the kernel.

`host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}` is a directory that contains a kernel config (`.config`) and a kernel source git submodule (`src`).

## Step 2) kexec

On host `${HOSTNAME}`, executing `./kbuild.sh host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION} host/${HOSTNAME}/cmdline/${APPEND}` reboots on ${KERNEL_LOCALVERSION} with the cmdline ${APPEND}.

`host/${HOSTNAME}/cmdline/${APPEND}` is a file that contains a cmdline.
