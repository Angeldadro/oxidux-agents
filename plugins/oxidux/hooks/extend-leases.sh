#!/usr/bin/env bash
# Antes de un Bash largo (timeout >= 5 min o en segundo plano) alarga los arriendos de Oxidux que tienes.
# Nunca bloquea el comando: ante cualquier fallo sale con 0 y sin salida.
[ -n "$OXIDUX_TOKEN" ] || exit 0
input=$(cat)

minutes=0
if printf '%s' "$input" | grep -q '"run_in_background"[[:space:]]*:[[:space:]]*true'; then
  minutes=30
else
  ms=$(printf '%s' "$input" | grep -o '"timeout"[[:space:]]*:[[:space:]]*[0-9]\+' | head -1 | grep -o '[0-9]\+$')
  if [ -n "$ms" ] && [ "$ms" -ge 300000 ]; then
    minutes=$(( ms / 60000 + 5 ))
  fi
fi
[ "$minutes" -gt 0 ] || exit 0
[ "$minutes" -le 120 ] || minutes=120

curl -s -m 10 -o /dev/null -X POST "${OXIDUX_MCP_URL:-https://api.oxidux.com/mcp}" \
  -A "oxidux-agents-hook/0.2" \
  -H "Authorization: Bearer $OXIDUX_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"extend_leases\",\"arguments\":{\"lease_minutes\":$minutes}}}" \
  || true
exit 0
