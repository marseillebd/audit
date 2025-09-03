#!/usr/bin/env bash
set -euo pipefail

# array holding all directories where projects should be located
PROJDIRS=( "$HOME/Documents/programming" "$HOME/Documents/sysadmin" )

PUBLISHED=( nanopass gateway-page typst-fitch )
# TODO upcomping: hss, kiss-tools, compiler-tools

# array holding location of all git directories (after `get_gitdirs`)
declare -a GITDIRS

main() {
  get_gitdirs
  projects_have_git
  git_right_place
  git_status
  # TODO check on the projects I maintain
  # TODO typos
}

get_gitdirs() {
  GITDIRS=( $(find "$HOME" -type d -name .git) )
  for i in ${!GITDIRS[@]}; do
    GITDIRS[i]="${GITDIRS[i]%/.git}"
  done
}

projects_have_git() {
  for projdir in ${PROJDIRS[@]}; do
    for dir in "$projdir"/*; do
      if [[ ! -d "$dir/.git" ]]; then
        echo "[WARNING] NO GIT: folder '$(basename "$dir")' in '$(tidypath "$projdir")'"
      fi
    done
  done
}

git_right_place() {
  local ok
  for gitdir in ${GITDIRS[@]}; do
    ok=0
    for projdir in ${PROJDIRS[@]}; do
      case "$gitdir" in
        "$projdir"/*) ok=1 ;;
      esac
      if [[ "$ok" != 0 ]]; then break; fi
    done
    if [[ "$ok" = 0 ]]; then
      echo "[WARNING] GIT MISPLACED: '$gitdir'"
    fi
  done
}

git_status() {
  local tmp
  for gitdir in ${GITDIRS[@]}; do
    tmp=$(git -C "$gitdir" status --porcelain=v1 | wc -l)
    if [[ "$tmp" != 0 ]]; then
      echo "[ERROR] UNCOMMITTED CHANGES: $tmp in '$(tidypath "$gitdir")'"
    fi
  done
  for gitdir in ${GITDIRS[@]}; do
    tmp=$(git -C "$gitdir" log --branches --not --remotes --oneline | wc -l)
    if [[ "$tmp" != 0 ]]; then
      echo "[ERROR] UNSYNCED BRANCHES: $tmp in '$(tidypath "$gitdir")'"
    fi
  done
  for gitdir in ${GITDIRS[@]}; do
    tmp=$(git -C "$gitdir" remote -v | wc -l)
    if [[ "$tmp" = 0 ]]; then
      echo "[WARNING] NO UPSTREAM: '$(tidypath "$gitdir")'"
    fi
  done
}

tidypath() {
  echo "$1" | sed $'s\r'"^$HOME"$'\r~\r' # WARNING might fail on some pathalogical home paths
}

main
