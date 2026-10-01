# Description

Two decoder.tunnels entries with the same (type, src, dst, session) key but different ids; the later one currently overwrites the earlier one silently.
With --init-errors-fatal the engine must refuse to start instead of silently
dropping or rewriting the tunnel definition.

# Ticket

https://redmine.openinfosecfoundation.org/issues/7674

# PCAP

Reuses decoder-tunnels-01 pcap.


# Lukas review comment

Seems like the best scenario:
With --init-errors-fatal the engine must refuse to start instead of silently
dropping or rewriting the tunnel definition