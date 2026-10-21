#!/bin/bash
# Usage: run-pcap.sh <thread name prefix> <pcap file or directory> [suricata args...]
#
# Runs Suricata over a pcap in autofp mode with 29 workers, with spin-delay.c
# delaying pthread_spin_lock() in the threads whose name starts with the given
# prefix. With 29 workers, the 33rd registered thread, which grows the thread
# store beyond its first 32 entries, is a management thread spawned after the
# flow manager, whatever the number of CPUs.
set -euo pipefail

prefix=$1
input=$2
shift 2
here=$(cd "$(dirname "$0")" && pwd)

cc -shared -fPIC -O1 -o "${OUTDIR}/spin-delay.so" "${here}/spin-delay.c" -ldl

ncpus=$(getconf _NPROCESSORS_ONLN)
ratio=$(python3 -c "print(29.5 / ${ncpus})")

# A dynamically linked ASAN runtime has to come first in LD_PRELOAD.
asan=$(ldd "${SRCDIR}/src/suricata" | awk '/libasan/ { print $3 }')

mkdir -p "${OUTDIR}/pcap-run"
# Suricata only handles SIGTERM once it runs, so a hung startup needs SIGKILL.
timeout -k 10 120 env SPIN_DELAY_THREADS="${prefix}" \
    LD_PRELOAD="${asan:+${asan} }${OUTDIR}/spin-delay.so" \
    "${SRCDIR}/src/suricata" -c "${SRCDIR}/suricata.yaml" -l "${OUTDIR}/pcap-run" \
    --set classification-file="${SRCDIR}/etc/classification.config" \
    --set reference-config-file="${SRCDIR}/etc/reference.config" \
    -r "${input}" --runmode=autofp -k none -S /dev/null \
    --set threading.set-cpu-affinity=no \
    --set threading.detect-thread-ratio="${ratio}" "$@" \
    > "${OUTDIR}/pcap-run.log" 2>&1
