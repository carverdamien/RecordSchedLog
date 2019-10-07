# RecordSchedLog

Tool to automate the following steps:

1) build a custom kernel with SchedLog.
2) kexec reboot with specific options.
3) run bench.

## Step 1) kbuild

On host `${HOSTNAME}`, executing `./kbuild.sh ./host/${HOSTNAME}/kernel/${KERNEL}` will build and install the kernel `${KERNEL}`.

`./host/${HOSTNAME}/kernel/${KERNEL}` is a directory that contains a kernel config (`.config`) and a kernel source git submodule (`src`).
