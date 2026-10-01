
Review findings: xdp-tunnel-7674-v27.5

  Numbers match the earlier mapping table. "Checked by me" means I ran the test and it fails. "Agent only" means only the review agent ran it (the live tests need sudo). "From the code" means there is no test for it.

  Bugs

  1. Reply traffic doesn't match its tunnel (src/decode.c:431)
  The tunnel key is (outer src, outer dst) in packet direction, so replies get PKT_TUNNEL_UNKNOWN. Each inner flow splits into two one-way flows, and on tunnel-ifaces every reply is skipped.
  - Test: decoder-tunnels-02-vxlan-bidir, checked by me.
  - Decision: D2.

  3. Startup crash on an empty mapping (src/detect-engine.c:4474, also :4465)
  An empty tunnel-id: or tenant-id: causes strlen(NULL) and a SIGSEGV. The bug was copied from the vlan loader.
  - Test: decoder-tunnels-04-mt-empty-mapping, checked by me (exit -11).
  - No decision needed; add the NULL check.

  4. Outer packets of known tunnels are skipped (src/decode.c:248)
  On tunnel-ifaces, every outer packet has tunnel_id == 0, so all of them are skipped. As a result pcap-log stays empty, rules on outer headers never fire, and outer flows are never tracked.
  - Test: live tunnel-ifaces-pcap-log, agent only.
  - Decision: D4.

  6. tunnel-ifaces without decoder.tunnels silently skips everything (src/decode.c:498)
  The code contradicts itself: PacketSetTunnelId deliberately doesn't skip when no tunnels are configured, but PacketDecodeFinalize and line 498 do.
  - Test: live tunnel-ifaces-no-tunnels, agent only.
  - Decision: D5.

  7. Tunnel config is barely validated (rust/src/decode.rs:109)
  - Bad entries, such as a mistyped type:, are only warned about and dropped.
  - Duplicate keys silently overwrite each other (HashMap::insert).
  - session isn't range-checked: VNI is 24 bits and the ERSPAN span ID is 10 bits.

  Tests: 10, 11 and 12, checked by me; startup succeeds. Decision: D6.

  8. selector: tunnel doesn't check the config (src/detect-engine.c:4664)
  If decoder.tunnels is missing, or a mapping names an undefined id, all traffic silently lands on the default tenant. The vlan selector refuses to start in the equivalent case.
  - Test: decoder-tunnels-09-mt-no-tunnels, checked by me.
  - Decision: D6.

  9. EVE schema has no top-level tenant_id (etc/schema.json:9594)
  This predates the branch, but your selector is what makes pcap multi-tenant tests possible, and they fail schema validation.
  - Test: decoder-tunnels-08-mt-selector, checked by me (fails on the schema check only).
  - No decision needed; add the field in the multi-tenant commit.

  10. eBPF tunnel encoding is dead code (src/util-ebpf.c:765)
  - Nothing in the tree writes the vlan1 & 0x8000 tunnel encoding.
  - If something ever did, & 0x7FFF would turn PKT_TUNNEL_UNKNOWN (0xFFFF) into the valid id 32767.
  - Separately, flow_key.vlan_id[2] is never initialised but is hashed. That bug is older than the branch, but it's in a function the branch touches.

  From the code. Decision: D7.

  Design question (no longer counted as a bug)

  5. On tunnel-ifaces, IPS and firewall fail open (src/flow-worker.c:572)
  Skipped packets bypass the firewall hook, detection and drop handling, so in IPS mode they are forwarded uninspected, and no counter records them. As we discussed, this matches the docs ("will be skipped").
  - The live tunnel-ifaces-ips-drop test currently asserts the opposite of the docs.
  - The live tunnel-ifaces-firewall test expects the firewall to still evaluate and block non-tunnel packets (ping fails, firewall.blocked: 5). It currently fails: all 5 pings pass and every firewall counter stays at 0. Without tunnel-ifaces, the same setup blocks all 5.
  - Decision: D1.

  Docs, style and code structure

  11. Docs not updated.
  - multi-tenant.rst:21 and :38 still list only direct, vlan and device selectors.
  - tunnel-ifaces has no syntax example and is missing from suricata.yaml.in.
  - The EVE tunnel_id field is undocumented.
  - The docs don't say that matching is IPv4-only and depends on direction.
  - "Skipped" should be spelled out: not inspected, and forwarded in IPS mode.

  12. Style.

  - if statements without braces: detect-engine.c 4458, 4461, 4852, 4855, 4861, and the failure_fatal goto.
  - Untouched lines reformatted: the detect.h:1720-1724 enum.
  - A stray blank line at bindgen.h:37.

  13. The skip decision is made in 5 places with inconsistent conditions (src/decode.c:256 and others). One check in FlowWorker would replace them. The #ifndef SURICATA_BINDGEN_H guard around about 1500 lines of decode.h, just to export one enum,
  would be simpler as a small dedicated header. Decision: D8.

  14. The tunnel multi-tenant loader and GetIdFromTunnel copy the vlan versions (src/detect-engine.c:4449). That's about 60 duplicated lines, including the crash from #3, and the "%d mappings defined" log was lost in the copy. Decision: D8.

  15. Small cleanups.
  - A stale "do not advance in packet" comment (decode-vxlan.c:217).
  - The VNI is computed twice. 
  - PacketReinit doesn't reset tproto.
  - Commit order: the ConfNode::value NULL fix (4ed0cf6be) comes after 4f83e5ecd, which already relies on it, so an empty id: can crash while bisecting.

  Former coverage finding (first review only). The original SV test checked very little. decoder-tunnels-01 now also checks the alert output (top-level tunnel_id and tunnel.tunnel_id, no tunnel_id on the outer flow), and new tests 06 (unknown tunnel) and 07 (defrag) cover the PKT_TUNNEL_UNKNOWN path and the tunnel id in the defrag key. All three pass.
  - 06 also shows that all unknown tunnels share PKT_TUNNEL_UNKNOWN, so the inner flows of different unconfigured tunnels are merged into one flow. Not a regression (they were merged before the PR too), but worth documenting.

  ---

  Decisions needed

  D1. IPS and firewall on tunnel-ifaces (#5).
  - (a) Keep failing open, document it, and add a skipped-packets counter.
  - (b) Refuse tunnel-ifaces in IPS or firewall mode at startup.
  - (c) Add a configurable policy for skipped packets: pass or drop.

  I'd recommend (a) now and (c) later if inline users need it. Once you decide, I'll rewrite tunnel-ifaces-ips-drop to match. I offered that earlier and it's still open.

  D2. Reply direction (#1).
  - (a) Match both directions automatically by putting the src/dst pair in a fixed order in the key.
  - (b) Require users to configure both directions, and document it.

  I'd recommend (a).

  D3. Which IP header identifies a nested tunnel (#2).
  - (a) The header that directly carries the tunnel.

  I'd recommend (a).

  D4. Outer packets of known tunnels (#4).
  - (a) Skip an outer packet only when it carries no known tunnel. This keeps pcap-log, outer flows and outer-header rules working.
  - (b) Skipping them is intended: document it and drop the pcap-log live test.

  I'd recommend (a).
  
  D5. tunnel-ifaces with no tunnels configured (#6).
  - (a) Startup error.
  - (b) Don't skip anything, matching what PacketSetTunnelId already does.
  
  I'd recommend (a). The live test assumes (b), so with (a) it becomes a startup-failure test.

  D6. How strict the config checks are (#7, #8).
  - (a) Always a fatal error.
  - (b) Fatal only with --init-errors-fatal, a warning otherwise, which is Suricata's usual convention.

  Tests 09–12 pass --init-errors-fatal explicitly and expect exit 1, so they assume (b). They currently fail: 10 only logs a plain warning, and 09, 11 and 12 log nothing, so the flag has no effect on any of them. Either way, duplicate keys should at least produce a warning.

  D7. eBPF (#10).
  - Remove the dead 0x8000 decoding until something writes it (I'd recommend this), or keep it and fix the UNKNOWN round trip.
  - Should the older vlan_id[2] initialisation bug be fixed in this PR or a separate one?

  D8. Refactors (#13, #14). Do the single skip check, the shared loader with vlan and the small enum header in this PR? I'd recommend at least the skip consolidation, because D1, D4 and D5 all change that logic anyway.

  D9. The new SV tests. These are uncommitted in ../suricata-dev-verify. Commit them once D1–D6 are settled, adjusting 04, 09–12 and the live ips-drop and no-tunnels tests to whatever you decide. Which suricata-verify branch should they go on?

  Housekeeping

  - live/tests/tunnel-ifaces-ips-drop/output/ is owned by root (from today's 10:52 run), so a run without sudo can't write there. Remove it with sudo rm -rf.
  - ../suricata-dev-verify/lib/__pycache__/ is stray and untracked.
  - suricata -V shows 5e3f2f085, a commit that isn't in this branch, even though the binary is current. Rerun ./configure to refresh it.
  - The findings panel from the first review doesn't include #9 (the schema finding).
