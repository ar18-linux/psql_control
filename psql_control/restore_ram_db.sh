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


function restore(){
  pg_ctl="${psql_dir}/bin/pg_ctl"
  db_name_requested="$1"
  backup_path="$2"
  set +e
  str="$(cat "${path_db_meta}" | grep "${db_name_requested}")"
  set -e
  if [ "${str}" = "" ]; then
    read -p "db not found: [${db_name_requested}]"
    exit 1
  fi
  stringarray=($str)
  source="${stringarray[1]}"
  source="${source%\"}"
  source="${source#\"}"
  port="${stringarray[2]}"
  
  read -p "Restore ${str}?"
  set +e
  su - "${db_user}" -c "${pg_ctl} -D ${source} stop -m f"
  set -e
  
  rm -rf "${source}"
  
  mkdir -p "${source}"
  chown "${db_user}" "${source}"
  
  su - "${db_user}" -c "${_7za} x -bsp1 ${backup_path} -aoa -o${source}" 
  
  sed -i -E "s/#?port = .+/port = ${port}/" "${source}/postgresql.conf"
  
  chmod 0700 "${source}"
  chown "${db_user}" "${source}"
  
  nohup su - "${db_user}" -c "${pg_ctl} -D ${source} start" &
  read -p "Restored ${db_name_requested}"
}


function run(){
  init_vars
  sanity_check
  db_name="$1"
  backup_path="$2"
  restore "${db_name}" "${backup_path}"
}


run "$@"

