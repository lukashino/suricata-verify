# Thread store reallocation: unix socket commands

Verifies that unix socket commands do not read the thread store while it is
reallocated during startup in offline mode.

With `unix-command.enabled: yes` in pcap-file mode, the unix socket thread
starts before the packet and management threads are set up. In offline mode,
`list-hostbit` reads the time from the packet threads in the thread store,
without the store lock. A thread registration that reallocates the store
before it is sealed then makes the command read the freed array.

The test needs an ASAN build. Its client script runs a second Suricata over a
pcap with `run-pcap.sh` from `thread-store-realloc-flow-manager`, with the
LD_PRELOAD shim delaying `pthread_spin_lock()` in the unix socket thread by
5 ms, and `hostbit-client.py` sending `list-hostbit` from the beginning of
startup. Suricata runs in continuous pcap mode until the client shuts it down,
after 10 commands answered once the engine started. Without the fix, ASAN
reports a heap-use-after-free in `TmThreadsGetMinimalTimestamp()`.

## Reference

- Redmine Ticket: https://redmine.openinfosecfoundation.org/issues/9249
