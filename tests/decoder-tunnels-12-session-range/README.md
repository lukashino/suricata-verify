# Description

An erspan2 session outside the 10-bit ERSPAN span id range (1345 > 1023) can never match a packet.
With --init-errors-fatal the engine must refuse to start instead of silently
dropping or rewriting the tunnel definition.

# Ticket

https://redmine.openinfosecfoundation.org/issues/7674

# PCAP

Reuses decoder-tunnels-01 pcap.
