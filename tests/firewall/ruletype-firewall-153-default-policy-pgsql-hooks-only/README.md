Test that accepting the generic app-layer hook aliases of a protocol is not
enough when the protocol has a hook in between them.

The generic request-/response-started and -complete aliases only name a
protocol's first and completion state. pgsql has a state between the two, and
all four aliases are set to accept:hook here, and all four are honoured. The
session is still blocked, because accept:hook only clears the hook it is set on
and hands evaluation to the next hook.

pgsql moves a request from progress 0 straight to its completion state in a
single parse step, so all three request hooks are evaluated while handling one
packet. On pcap_cnt 4, the first packet carrying app-layer data, progress 0 is
accepted by request-started, evaluation advances to the state in between, and
the flow is dropped there by the built-in drop:flow. The completion state is
never reached, so the request-complete setting never comes into play.

The drop is at the app layer, not below it. The TCP handshake is accepted by the
packet hooks (firewall.accepted is 3), the flow reaches the established state
and is detected as pgsql, and one pgsql transaction is parsed.
default_packet_policy stays 0, and no stream, reassembly or app-layer parser
error is counted, so no lower layer contributed to the block.

That middle hook is named, so either naming it (request-received) or setting a
default-policy tier that covers it passes the whole session. The counterpart
test ruletype-firewall-152-default-policy-pgsql-proto-default takes the tier
route.
