The IPv6 counterpart to `ips-drop-icmp-afp`: ICMPv6 echo requests are dropped
inline while the client pings the server over IPv6.

It doubles as the regression test for IPv6 addressing in the harness. The
packet counts are asserted exactly, which only holds because IPv6
autoconfiguration is quiesced during namespace setup (see `quiet_ipv6` in
`run.py`) -- with autoconf left on, the router solicitations and multicast
listener reports it emits arrive at times nothing in the test controls.
