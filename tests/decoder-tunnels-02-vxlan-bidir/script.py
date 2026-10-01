#!/usr/bin/env python
from scapy.all import *

def vxlan(src, dst, inner):
    return Ether()/IP(src=src, dst=dst)/UDP(sport=4789, dport=4789)/VXLAN(flags=0x08, vni=123)/Ether()/inner

a = '192.168.1.3'
b = '192.168.1.2'
pkts = [
    vxlan(a, b, IP(src='10.0.0.1', dst='10.0.0.2')/UDP(sport=5000, dport=6000)/"request"),
    vxlan(b, a, IP(src='10.0.0.2', dst='10.0.0.1')/UDP(sport=6000, dport=5000)/"reply"),
]
wrpcap('input.pcap', pkts)
