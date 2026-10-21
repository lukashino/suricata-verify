# Thread store reallocation: flow manager

Verifies that the flow manager does not read the thread store while it is
reallocated during startup in offline mode.

In offline mode, the flow manager polls whether the packet threads have set
their first timestamps from the moment it is spawned. Thread registrations
after the flow manager, before the thread store is sealed, can reallocate the
store when it is full. A flow manager reading the store without the store lock
then reads the freed array.

The test needs an ASAN build. The live runner's own Suricata is not used: the
client script runs `run-pcap.sh`, which runs a second Suricata over a pcap in
autofp mode with 29 workers, so that the 33rd registered thread, which grows the
store beyond its first 32 entries, is a management thread spawned after the
flow manager. The `spin-delay.c` LD_PRELOAD shim sleeps for 20 ms after every
`pthread_spin_lock()` in the flow manager thread, so that the flow manager reads
the store during nearly all of the startup. Without the fix, ASAN reports a
heap-use-after-free in `TmThreadsTimeSubsysIsReady()`.

`run-pcap.sh` and `spin-delay.c` are also used by
`thread-store-realloc-unix-command`.

## Reference

- Redmine Ticket: https://redmine.openinfosecfoundation.org/issues/9249
