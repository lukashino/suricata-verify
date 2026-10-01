# tunnel-ifaces without decoder.tunnels

`br0` is listed in `decoder.tunnel-ifaces` but no `decoder.tunnels` are
defined. Without any tunnel definition nothing can ever match, so traffic must
not be silently skipped (PacketSetTunnelId already only skips when a tunnel
map exists): plain ICMP must still be inspected.

Ticket: https://redmine.openinfosecfoundation.org/issues/7674

# Lukas review comment

This test might not necessarily pass. It is up for a discussion of what the behavior should be for packets not matching any tunnel.
But I would suggest to at least do a startup error/warning in case the iface has been defined in tunnel-ifaces but no tunnel is defined.