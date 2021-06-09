#!/bin/bash

set -e
set -x

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

. "${script_dir}/helper_funcs.sh"


function init_vars(){
  echo init_vars
  import_vars_helper
}


function sanity_check(){
  echo sanity_check
  sanity_check_helper
}


function start(){
  echo start
  mkdir -p /run/postgres
  chown "${db_user}:${db_user}" /run/postgres
  if [ "${db_name}" = "" ]; then
    str="$(grep '[[:alnum:]]' "${path_db_meta}" | tail -n 1 | xargs)"
    declare -A lines
    lines[0]=str
  elif [ "${db_name}" = "all" ]; then
    IFS=$'\r\n' GLOBIGNORE='*' command eval "lines=(\$(cat "${path_db_meta}"))"
    str="${db_name}"
  else
    set +e
    str="$(cat "${path_db_meta}" | grep -E "^[\"\']?${db_name}")"
    set -e
    declare -A lines
    lines[0]="${str}"
  fi
  if [ "${lines[0]}" = "" ]; then
    read -p "db not found: [${db_name}]"
    exit 1
  fi
  read -p "start ${str}?"
  errors=0
  for line in "${lines[@]}"; do
    trimmed="$(echo $line | xargs)"
    if [ "${trimmed:0:1}" != "#" ]; then
      source="$(read_source_part "${line}")"
      pg_ver="$(read_version_part "${line}")"
      pg_ctl="$(fetch_psql_dir "${pg_ver}")/bin/pg_ctl"
      pid=-1
      if [ -f "${source}/postmaster.pid" ]; then
        pid="$(cat "${source}/postmaster.pid" | head -1)"
        kill -0 "${pid}" || pid=-1
      fi
      set +e
      if [ "${pid}" = "-1" ]; then
        su - "${db_user}" -c "${pg_ctl} -D ${source} start"
        ret=$?
        if [ "${ret}" != "0" ]; then
          echo "failed to start ${line}" >&2
          errors=$((errors + 1))
        else
          echo "started ${source}"
        fi
      else
        echo "already started: ${source}"
      fi
      set -e
    fi
  done
  if [ "${errors}" != "0" ]; then
    read -p "Failed to start some entries, press a key"
  else
    read -p "Started ${str}, press a key"
  fi
}


function run(){
  db_name="$1"
  init_vars
  sanity_check
  start
}


run "$@"
