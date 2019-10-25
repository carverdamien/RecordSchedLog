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

## How to add a new host

Install dependencies
```
git
# required for scripts/kbuild.sh
build-essential
bison
flex
libelf-dev
bc
openssl
libssl-dev
# required for scripts/kexec.sh
kexec-tools 
# required for monitoring/cpu-energy-meter monitoring/all
cpu-energy-meter https://github.com/sosy-lab/cpu-energy-meter 
# required for bench/llvm
cmake
# required for bench/phoronix
phoronix-test-suite
# required for monitoring/schedlog
python
numpy
pandas
# required for callback_run_bench.sh
rsync
```
Create directories and files
```
# host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}/src (required)
$ git submodule add -b BRANCH GIT_REPO host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}/src

# host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}/config (required)
$ cd host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}/src; make oldconfig; cp .config ../config

# host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}/{kbuild-post-install-hook.sh} (required for sched_log, perf, ipanema_modules etc ..)

# host/${HOSTNAME}/cmdline/intel_sleep_state_{enable,disable}
```
