#! /bin/bash

set -e
set -x

# tshark buffers its JSON output and only writes the closing bracket on a clean
# shutdown, so it has to outlive the server and get a SIGINT of its own.
# Otherwise the container takes it down with a SIGKILL and
# /out/tshark-server.json is left empty -- which a "no packets reached the
# server" check reads as a pass whether or not that is true.
tshark_pid=""
caddy_pid=""

shutdown() {
    # Stop the server first so tshark still sees anything it emits on the way
    # out, then let tshark close its JSON array.
    if [ -n "${caddy_pid}" ]; then
        kill -TERM "${caddy_pid}" 2>/dev/null || true
        wait "${caddy_pid}" 2>/dev/null || true
        caddy_pid=""
    fi
    if [ -n "${tshark_pid}" ]; then
        kill -INT "${tshark_pid}" 2>/dev/null || true
        wait "${tshark_pid}" 2>/dev/null || true
        tshark_pid=""
    fi
}

# Keep these separate: the EXIT trap must not override a non-zero status, and
# the signal traps must exit rather than fall through to the wait below.
trap shutdown EXIT
trap 'shutdown; exit 0' INT TERM

echo "Starting tshark..."
tshark -i server -f icmp -T json > /out/tshark-server.json 2> /out/tshark-server.stderr &
tshark_pid=$!

echo "Starting caddy..."
cd /srv/www
caddy file-server browse &
caddy_pid=$!

# Fail loudly if either one never came up, rather than running the test against
# a server that is not listening or a capture that is not recording -- a missed
# packet would otherwise read as a pass. Note this does not gate the client:
# the harness waits a fixed grace period for the server script, it does not
# wait for this readiness to be reached. The caddy probe runs over loopback
# inside this namespace, so it adds nothing to the wire Suricata is watching.
echo "Waiting for tshark..."
for _ in $(seq 1 100); do
    if grep -q "Capturing on" /out/tshark-server.stderr 2>/dev/null; then
        break
    fi
    sleep 0.1
done
grep -q "Capturing on" /out/tshark-server.stderr

echo "Waiting for caddy..."
for _ in $(seq 1 100); do
    if (exec 3<>/dev/tcp/127.0.0.1/80) 2>/dev/null; then
        break
    fi
    sleep 0.1
done
(exec 3<>/dev/tcp/127.0.0.1/80) 2>/dev/null

echo "Server ready"
wait "${caddy_pid}"
