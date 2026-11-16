#!/usr/bin/env bash
set -euo pipefail
core_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$core_dir/host/source-origin.func"
for repo in core ProxmoxVE ProxmoxVE-Local; do
  for remote in "https://github.com/remz1337/$repo.git" "git@github.com:remz1337/$repo.git" "ssh://git@github.com/remz1337/$repo.git"; do
    for branch in main merge HEAD remz; do
      [[ "$(cs_git_remote_to_raw_base "$remote" "$branch")" == "https://raw.githubusercontent.com/remz1337/$repo/remz" ]]
    done
  done
done
# Other repositories retain their configured branch.
[[ "$(cs_git_remote_to_raw_base https://github.com/example/custom.git feature)" == https://raw.githubusercontent.com/example/custom/feature ]]
echo 'PASS: fork origins use remz regardless of checkout branch'
