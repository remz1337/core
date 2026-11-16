#!/usr/bin/env bash
# Verify that opted-in settings cannot enable reporting in this fork.
set -euo pipefail
CORE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT
export FORK_NETWORK_LOG="$work_dir/network"
: >"$FORK_NETWORK_LOG"
curl() { printf '%s\n' "$*" >>"$FORK_NETWORK_LOG"; return 99; }
wget() { printf '%s\n' "$*" >>"$FORK_NETWORK_LOG"; return 99; }
export -f curl wget
source "$CORE_DIR/api/telemetry.func"
DIAGNOSTICS=yes RANDOM_UUID=test POST_TO_API_DONE=true
TELEMETRY_TIMEOUT=1 STATUS_TIMEOUT=1
if _tm_enabled; then
  echo 'FAIL: telemetry enabled despite fork policy' >&2
  exit 1
fi
_tm_payload() { echo 'FAIL: telemetry payload collected' >&2; return 99; }
_tm_send '{}'
post_to_api
post_progress_to_api
post_update_to_api failed 1 force
post_tool_to_api example success 0
post_addon_to_api example success 0
# Extract standalone definitions without bootstrapping a container or host UI.
load_function() {
  eval "$(awk -v name="$2" '$0 == name "() {" {copy=1} copy {print} copy && /^}$/ {exit}' "$1")"
}
load_function "$CORE_DIR/lxc/install.func" post_progress_to_api
post_progress_to_api configuring
for function_name in diagnostics_check runtime_script_status_guard check_breaking_change_guard; do
  load_function "$CORE_DIR/ui/menu.func" "$function_name"
  "$function_name"
done
[[ "$DIAGNOSTICS" == no ]]
# The updater may fetch fork scripts, but must never query a status service.
curl() {
  printf '%s\n' "$*" >>"$FORK_NETWORK_LOG"
  [[ "${*: -1}" == 'https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/ct/debian.sh' ]] || return 99
  [[ " $* " == *' -o /dev/null '* ]] || printf 'exit 0\n'
}
export -f curl
SCRIPT_SLUG=debian UPDATE_SCRIPT_NAME=debian bash "$CORE_DIR/misc/update.sh"
[[ "$(wc -l <"$FORK_NETWORK_LOG")" -eq 2 ]]
! grep -Eq 'telemetry|community-scripts.org' "$FORK_NETWORK_LOG"
echo 'PASS: telemetry and website metadata queries stay disabled; updater uses fork'
