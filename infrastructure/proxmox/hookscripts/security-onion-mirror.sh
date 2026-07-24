#!/bin/bash
# Hookscript for security onion. Re-applies tc mirred rules and promiscuous mode on the sniffing tap interface after the VM starts in Proxmox.

VMID="$1"
PHASE="$2"

if [ "$PHASE" = "post-start" ]; then
    # Give the tap interface a moment to fully register
    sleep 5

    ip link set tap200i1 promisc on
    ip link set tap200i1 up

    # Ingress qdisc may already exist from a prior start. ignore error if so
    tc qdisc add dev vmbr99 handle ffff: ingress 2>/dev/null || true

    tc filter add dev vmbr99 parent ffff: protocol 802.1Q flower vlan_id 130 action mirred egress mirror dev tap200i1
    tc filter add dev vmbr99 parent ffff: protocol 802.1Q flower vlan_id 140 action mirred egress mirror dev tap200i1
    tc filter add dev vmbr99 parent ffff: protocol 802.1Q flower vlan_id 110 action mirred egress mirror dev tap200i1
    # Insert future VLANs here
    
    logger "security-onion-mirror hookscript: tc mirred rules applied for VMID ${VMID}"