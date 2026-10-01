#!/usr/bin/env python
from scapy.all import *

def vxlan(src, dst, vni):
    return Ether()/IP(src=src, dst=dst)/UDP(sport=4789, dport=4789)/VXLAN(flags=0x08, vni=vni)/Ether()/IP(src='10.1.2.4', dst='10.1.2.3')/ICMP(type=8)/"same"

pkts = [
    vxlan('192.168.1.3', '192.168.1.2', 123),  # configured tunnel id 2
    vxlan('192.168.1.3', '192.168.1.2', 999),  # unknown vni
    vxlan('192.168.1.5', '192.168.1.2', 123),  # unknown endpoint
]
wrpcap('input.pcap', pkts)
