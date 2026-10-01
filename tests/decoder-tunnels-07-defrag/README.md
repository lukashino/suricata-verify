# Description

Fragments with identical inner tuple and IP id arrive interleaved through two
different tunnels. The tunnel id is part of the defrag key, so each tunnel
reassembles its own datagram.

# Ticket

https://redmine.openinfosecfoundation.org/issues/7674

# PCAP

Crafted with scapy script.py
