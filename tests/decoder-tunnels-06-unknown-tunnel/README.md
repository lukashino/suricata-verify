# Description

Same inner flow seen through a configured tunnel and through unconfigured
ones (unknown VNI, unknown endpoint). The configured tunnel flow must not be
merged with the unknown ones, and unknown tunnels are logged without
tunnel_id.

All unknown tunnels share the same id (PKT_TUNNEL_UNKNOWN), so the inner
flows of the two unknown tunnels are merged into one flow.

# Ticket

https://redmine.openinfosecfoundation.org/issues/7674

# PCAP

Crafted with scapy script.py
