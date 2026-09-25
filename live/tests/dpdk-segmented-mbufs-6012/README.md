# DPDK segmented mbufs (Ticket #6012)

Verifies that Suricata handles segmented (chained) mbufs in DPDK mode.

DPDK's pcap virtual PMD attaches to the tap bridge `br0`. The interface MTU of
256 sizes the mbufs to 1024 bytes, so the PMD chains larger frames across
multiple mbufs. The bridged path runs with a 9000 byte MTU and the client pings
with 1442 byte frames (2 mbufs, fits into a standard Packet p buffer) and 9014
byte jumbo frames (8 mbufs, requires extending the buffer through extra
allocations). The rules require an intact ICMP checksum over the whole payload
and the ping pattern in its last bytes, which only the last mbuf segment holds.

## Reference

- Redmine Ticket: https://redmine.openinfosecfoundation.org/issues/6012
