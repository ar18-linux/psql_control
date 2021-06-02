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


function stop(){
  echo stop
  if [ "${db_name}" = "" ]; then
    str="$(grep '[[:alnum:]]' "${path_db_meta}" | tail -n 1 | xargs)"
    declare -A lines
    lines[0]=str
  elif [ "${db_name}" = "all" ]; then
    IFS=$'\r\n' GLOBIGNORE='*' command eval "lines=(\$(cat "${path_db_meta}"))"
    str="${db_name}"
  else
    set +e
    str="$(read_configuration "${db_name}" "${path_db_meta}")"
    set -e
    declare -A lines
    lines[0]="${str}"
  fi
  if [ "${lines[0]}" = "" ]; then
    read -p "db not found: [${db_name}]"
    exit 1
  fi
  read -p "stop ${str}?"
  for line in "${lines[@]}"; do
    trimmed="$(echo $line | xargs)"
    if [ "${trimmed:0:1}" != "#" ]; then
      source="$(read_source_part "${line}")"
      pg_ver="$(read_version_part "${line}")"
      pg_ctl="$(fetch_psql_dir "${pg_ver}")/bin/pg_ctl"
      set +e
      su - "${db_user}" -c "${pg_ctl} -D ${source} stop -m f"
      set -e
    fi
  done
  
  read -p "Stopped ${str}, press a key"
}


function run(){
  db_name="$1"
  init_vars
  sanity_check
  stop 
}


run "$@"
