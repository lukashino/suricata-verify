"""Send list-hostbit commands over the unix socket from the start of
Suricata's startup, then shut Suricata down once it answered commands after
the engine started."""

import json
import socket
import sys
import time

sock_path, log_path = sys.argv[1], sys.argv[2]
deadline = time.monotonic() + 120


def engine_started():
    try:
        with open(log_path) as log:
            return "Engine started" in log.read()
    except OSError:
        return False


while True:
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.connect(sock_path)
        connected_early = not engine_started()
        break
    except OSError:
        sock.close()
        if time.monotonic() > deadline:
            sys.exit("error: the unix socket never appeared")
        time.sleep(0.001)
sock.settimeout(60)
print(f"connected before engine start: {connected_early}", flush=True)
conn = sock.makefile("rw")


def call(command):
    conn.write(json.dumps(command) + "\n")
    conn.flush()
    reply = conn.readline()
    if not reply:
        sys.exit("error: Suricata closed the connection")
    return json.loads(reply)


call({"version": "0.2"})
startup = running = 0
while running < 10:
    if time.monotonic() > deadline:
        call({"command": "shutdown"})
        sys.exit("error: timed out")
    started = engine_started()
    call({"command": "list-hostbit", "arguments": {"ipaddress": "10.0.0.1"}})
    if started:
        running += 1
    else:
        startup += 1
print(f"list-hostbit replies: {startup} during startup, {running} after engine start")
call({"command": "shutdown"})
