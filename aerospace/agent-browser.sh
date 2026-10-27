#!/bin/zsh
# "Agent Helium": a second Helium process for browser automation, driven over
# CDP (chrome-devtools MCP) on 127.0.0.1:9333. It uses its own data dir
# (~/.helium-agent, a copy of my 36 Labs profile), so agents never see my own
# windows/tabs. Launched with `open -g` so it never takes focus; aerospace.toml
# parks its windows on hidden workspace Z (titles end in "– Agent").
#
#   agent-browser.sh start    start if not running (idempotent)
#   agent-browser.sh stop     quit it
#   agent-browser.sh sync     stop, copy cookies from my 36 Labs profile, start
#   agent-browser.sh status   print running/port state
#   agent-browser.sh mcp      start, then run chrome-devtools MCP (stdio) against it
#   agent-browser.sh guard    (exec-on-workspace-change) if agent Helium pulled
#                             focus to Z, go back. `touch /tmp/agent-z-allow`
#                             to look at Z yourself.
AEROSPACE=/opt/homebrew/bin/aerospace
PORT=9333
DATA=$HOME/.helium-agent
SRC="$HOME/Library/Application Support/net.imput.helium/Profile 3"

running() { /usr/bin/curl -s -m 1 "http://127.0.0.1:$PORT/json/version" >/dev/null; }
agent_pids() { /usr/bin/pgrep -f -- "--user-data-dir=$DATA" | while read p; do ps -o comm= -p $p | grep -q 'Helium$' && echo $p; done; }

ensure_titles() {
  # A second (unused) profile entry makes Helium append "– Agent" to window
  # titles, which is what the aerospace rule matches.
  /usr/bin/python3 - "$DATA/Local State" <<'PY'
import json,sys,os
p=sys.argv[1]; d=json.load(open(p)) if os.path.exists(p) else {}
c=d.setdefault('profile',{}).setdefault('info_cache',{})
c.setdefault('Default',{})['name']='Agent'; c['Default']['is_using_default_name']=False
c.setdefault('Profile 9',{'name':'unused','is_using_default_name':False})
d['profile']['last_used']='Default'
open(p,'w').write(json.dumps(d))
PY
  /bin/mkdir -p "$DATA/Profile 9"
}

start() {
  running && return 0
  ensure_titles
  /usr/bin/open -g -n -a /Applications/Helium.app --args --user-data-dir="$DATA" \
    --remote-debugging-port=$PORT --remote-debugging-address=127.0.0.1 \
    --no-first-run --no-default-browser-check --profile-directory=Default about:blank
  for _ in {1..40}; do running && return 0; /bin/sleep 0.25; done
  echo "agent Helium did not start" >&2; return 1
}

stop() {
  local pids=($(agent_pids)); [[ ${#pids} -eq 0 ]] && return 0
  kill -TERM $pids 2>/dev/null
  for _ in {1..40}; do [[ -z "$(agent_pids)" ]] && return 0; /bin/sleep 0.25; done
  kill -KILL $(agent_pids) 2>/dev/null; return 0
}

sync_cookies() {
  stop
  /usr/bin/sqlite3 "file:$SRC/Cookies?mode=ro" ".backup '$DATA/Default/Cookies.new'" &&
    /bin/mv -f "$DATA/Default/Cookies.new" "$DATA/Default/Cookies" &&
    /bin/rm -f "$DATA/Default/Cookies-journal" "$DATA/Default/Cookies-wal" "$DATA/Default/Cookies-shm"
  start
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
  sync) sync_cookies ;;
  mcp)
    start >&2 || exit 1
    exec /opt/homebrew/bin/npx -y chrome-devtools-mcp@latest --browserUrl "http://127.0.0.1:$PORT" --no-usage-statistics ;;
  guard)
    [[ $AEROSPACE_FOCUSED_WORKSPACE == Z && ! -e /tmp/agent-z-allow && -n $AEROSPACE_PREV_WORKSPACE ]] || exit 1
    $AEROSPACE workspace "$AEROSPACE_PREV_WORKSPACE" ;;
  status) running && echo "running on :$PORT ($(agent_pids | tr '\n' ' '))" || echo "not running" ;;
  *) echo "usage: agent-browser.sh [start|stop|sync|status]" >&2; exit 2 ;;
esac
