Test that naming every progress state of a protocol passes a session without
any default-policy tier.

pgsql has a progress state between its first and its completion state. The
generic request-/response-started and -complete aliases do not name it, so a
config that sets only those four is still blocked - see
ruletype-firewall-153-default-policy-pgsql-hooks-only.

Here every state is named by its parser state name instead, so all six hooks are
accepted and the session runs to completion: all six transactions are parsed and
logged, the flow closes normally and nothing is dropped.

This is the same result as ruletype-firewall-152-default-policy-pgsql-proto-default
reaches through app.pgsql.default-policy, so the two tests cover the two ways of
supplying a policy for every hook.
