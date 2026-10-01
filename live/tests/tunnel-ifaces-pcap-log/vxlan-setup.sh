#!/bin/bash
# Create a VXLAN (vni 123) overlay 172.16.0.0/24 between client0 and server0.
set -euo pipefail

ip -n client0 link add vx0 type vxlan id 123 remote 10.200.0.1 dstport 4789 dev client
ip -n client0 addr add 172.16.0.2/24 dev vx0
ip -n client0 link set vx0 up

ip -n server0 link add vx0 type vxlan id 123 remote 10.200.0.2 dstport 4789 dev server
ip -n server0 addr add 172.16.0.1/24 dev vx0
ip -n server0 link set vx0 up
