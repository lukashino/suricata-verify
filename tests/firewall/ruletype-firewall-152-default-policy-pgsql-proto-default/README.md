Test that a per-protocol default-policy covers every app-layer hook of a
protocol without any hook having to be named.

pgsql has a progress state between its first and its completion state, so the
generic request-/response-started and -complete aliases do not cover all of its
hooks on their own.

app.pgsql.default-policy covers all of them, so the session runs to completion:
all six transactions are parsed and logged, the flow closes normally and nothing
is dropped.

The counterpart test ruletype-firewall-153-default-policy-pgsql-hooks-only
accepts only the four generic aliases and is blocked, which shows the tier is
doing the work rather than the aliases.
