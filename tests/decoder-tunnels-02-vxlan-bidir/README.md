# Description

VXLAN is bidirectional: the reply leaves the remote VTEP, so its outer header
is dst->src of the configured tunnel. Both directions of the inner flow must
map to the same tunnel id and stay in a single flow.

# Ticket

https://redmine.openinfosecfoundation.org/issues/7674

# PCAP

Crafted with scapy script.py


# Lukas review comment

For bidir vxlan you need to specify two same ID tunnels to match it properly, does it make sense to separate it, or can we automatically swap it so the user only specifies the tunnel once? More in suricata.yaml

Also, the docs could mention that the tunnel must be the outermost IPv4 encapsulation (if it will be encapsulated within e.g. GRE it will not work) and that IPv6 addresses are not supported.

