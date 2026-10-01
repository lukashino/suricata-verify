# Description

A decoder.tunnels entry with an unknown type (typo `erspan` instead of `erspan2`).
With --init-errors-fatal the engine must refuse to start instead of silently
dropping or rewriting the tunnel definition.

# Ticket

https://redmine.openinfosecfoundation.org/issues/7674

# PCAP

Reuses decoder-tunnels-01 pcap.

# Lukas review comment

Few cases of what typos can happen, I would consider even erroring out on most of these. But if not, then at least adding an error on out of range session identifiers (extra mentioned in decoder-tunnels-12-session-range test).
Also, perhaps we can change SCLogWarnings to SCFatalErrorOnInit! so Suricata doesn't start when ran with --init-errors-fatal .

  ┌─────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────┐
  │                                          Typo                                           │                         Result                          │
  ├─────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ type: not exactly vxlan or erspan2 (including VXLAN, since the match is case-sensitive) │ warning, entry dropped                                  │
  ├─────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ id: 0 or 32768–65535                                                                    │ warning, entry dropped                                  │
  ├─────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ id: non-numeric or above 65535                                                          │ warning saying "missing id" (misleading), entry dropped │
  ├─────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ src or dst not a valid IPv4 address                                                     │ warning, entry dropped                                  │
  ├─────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ misspelled key name (sesion:, tpye:)                                                    │ treated as missing: warning, entry dropped              │
  ├─────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ session out of range (VNI over 24 bits, span ID over 10 bits)                           │ no warning; never matches ( could at least warn)        │
  └─────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────┘
