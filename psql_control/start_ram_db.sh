#!/bin/bash

set -e
set -x

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


function init_vars(){
  echo init_vars
  if [ -f "/home/$(logname)/.config/ar18/psql_control/vars" ]; then
    . "/home/$(logname)/.config/ar18/psql_control/vars"
    path_db_meta="/home/$(logname)/.config/ar18/psql_control/dbs.txt"
  else
    . "${script_dir}/vars"
    path_db_meta="${script_dir}/dbs.txt"
  fi
}


function sanity_check(){
  echo sanity_check
  if [[ "$(whoami)" != "root" ]]; then
    read -p "not root"
    exit 1
  fi
  if [ ! -f "${path_db_meta}" ]; then
    read -p "db meta path not found: [${path_db_meta}]"
  fi
  echo "_7za: ${_7za}"
  echo "psql_dir: ${psql_dir}"
  echo "ram_db_dir: ${ram_db_dir}"
  echo "target: ${target}"
  echo "db_user: ${db_user}"
}


function start(){
  echo start
  db_name_requested="$1"
  if [ "${db_name_requested}" = "" ]; then
    str="$(grep '[[:alnum:]]' "${path_db_meta}" | tail -n 1 | xargs)"
    declare -A lines
    lines[0]=str
  elif [ "${db_name_requested}" = "all" ]; then
    IFS=$'\r\n' GLOBIGNORE='*' command eval "lines=(\$(cat "${path_db_meta}"))"
    str="${db_name_requested}"
  else
    set +e
    str="$(cat "${path_db_meta}" | grep "${db_name_requested}")"
    set -e
    declare -A lines
    lines[0]="${str}"
  fi
  if [ "${lines[0]}" = "" ]; then
    read -p "db not found: [${db_name_requested}]"
    exit 1
  fi
  read -p "start ${str}?"
  pg_ctl="${psql_dir}/bin/pg_ctl"
  for line in "${lines[@]}"; do
    trimmed="$(echo $line | xargs)"
    if [ "${trimmed:0:1}" != "#" ]; then
      stringarray=($trimmed)
      source="${stringarray[1]}"
      nohup su - "${db_user}" -c "${pg_ctl} -D ${source} start" &
    fi
  done
  
  read -p "Started, press a key"
}


function run(){
  init_vars
  sanity_check
  db_name="$1"
  start "${db_name}"
}


run "$@"
