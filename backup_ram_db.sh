#!/bin/bash

set -x
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


function init_vars(){
  echo init_vars
  . "${script_dir}/vars"
}


function sanity_check(){
  echo sanity_check
  if [[ "$(whoami)" != "root" ]]; then
    read -p "not root"
    exit 1
  fi
  echo "_7za: ${_7za}"
  echo "psql_dir: ${psql_dir}"
  echo "ram_db_dir: ${ram_db_dir}"
  echo "target: ${target}"
  echo "db_user: ${db_user}"
}


function backup(){
  echo backup
  pg_ctl="${psql_dir}/bin/pg_ctl"

  str="$(grep '[[:alnum:]]' "${script_dir}/dbs.txt" | tail -n 1 | xargs)"
  stringarray=($str)
  source="${stringarray[0]}"
  port="${stringarray[1]}"
  sub_dir="default"
  
  if [ -n "$port" ]; then
    sub_dir="${port}"
  fi
  
  date="$(date '+%Y_%m_%d_%H_%M')"
  
  ram_db="${ram_db_dir}/${sub_dir}"
  
  chmod 0777 "${target}" -R
  
  #pid=$(head -1 "${ram_db}/postmaster.pid")
  
  read -p "backup ${ram_db}?"
  set +e
  su - "${db_user}" -c "${pg_ctl} -D ${ram_db} stop -m f"
  set -e
  
  echo "creating 7z archive..."
  "${_7za}" a -bsp1 "${target}/local_${date}.7z" "${ram_db}/*" 
  
  chmod 0777 "${target}/local_${date}.7z"
  
  su - "${db_user}" -c "${pg_ctl} -D ${ram_db} start"
  
  echo "backed up as ${date}.7z"
  read -p "Press a key"
}


function run(){
  init_vars
  sanity_check
  backup
}


run
