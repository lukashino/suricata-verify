# tunnel-ifaces in firewall mode

Suricata runs inline (AF_PACKET copy-mode IPS) in firewall mode. The firewall
ruleset accepts ARP only, so ICMP hits the default drop policy. Both interfaces
are listed in `decoder.tunnel-ifaces` and a tunnel is defined in
`decoder.tunnels`. The client sends 5 plain (non-tunneled) ICMP echo requests.

Skipping packets that do not belong to a defined tunnel must not bypass the
firewall: the firewall must still evaluate them, so all 5 echo requests are
blocked (`firewall.blocked: 5`) and the ping fails. This is the result the same
setup gives without `tunnel-ifaces`.

Ticket: https://redmine.openinfosecfoundation.org/issues/7674
