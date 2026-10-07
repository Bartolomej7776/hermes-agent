#!/usr/bin/env bash
# hermes-dashboard shares hermes-agent's PID namespace (pid: service:hermes), so it
# dies whenever hermes-agent stops, and Docker's restart policy gives up after
# "failed to join PID namespace" while hermes-agent is still down. Start the
# dashboard again each time hermes-agent comes up.
set -u

start_dashboard() {
  for _ in 1 2 3 4 5 6; do
    [ "$(docker inspect -f '{{.State.Running}}' hermes-dashboard 2>/dev/null)" = true ] && return 0
    docker start hermes-dashboard >/dev/null 2>&1 && { echo "started hermes-dashboard"; return 0; }
    sleep 5
  done
  echo "failed to start hermes-dashboard" >&2
}

if [ "$(docker inspect -f '{{.State.Running}}' hermes-agent 2>/dev/null)" = true ]; then
  start_dashboard
fi

docker events --filter container=hermes-agent --filter event=start --format '{{.Time}}' |
  while read -r _; do
    sleep 3
    start_dashboard
  done
