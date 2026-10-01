#!/usr/bin/env python
from scapy.all import *

# same inner 5-tuple and IP id in two tunnels, fragments interleaved
def frags(payload):
    big = IP(src='10.5.5.4', dst='10.5.5.5', id=77)/UDP(sport=1111, dport=2222)/(payload * 3000)
    return fragment(big, fragsize=1000)

def vxlan(vni, inner):
    return Ether()/IP(src='192.168.1.3', dst='192.168.1.2')/UDP(sport=4789, dport=4789)/VXLAN(flags=0x08, vni=vni)/Ether()/inner

a = frags("A")
b = frags("B")
pkts = []
for fa, fb in zip(a, b):
    pkts.append(vxlan(123, fa))
    pkts.append(vxlan(456, fb))
wrpcap('input.pcap', pkts)
