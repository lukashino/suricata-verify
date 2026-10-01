# tunnel-ifaces: pcap-log on a tunnel interface

Client and server exchange ICMP over a real VXLAN tunnel (vni 123) that is
configured in `decoder.tunnels` (both directions), and `br0` is listed in
`decoder.tunnel-ifaces`.

The inner traffic must be inspected (alerts with tunnel_id 1) and pcap-log
must still record the captured (outer) packets. Outer packets always have
tunnel_id 0, so they must not be skipped entirely.

Ticket: https://redmine.openinfosecfoundation.org/issues/7674


# Lukas review comment

Currently the packets are not recorded even though they are inspected.