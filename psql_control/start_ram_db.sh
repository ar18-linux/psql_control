#!/bin/bash

set -e
set -x

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


function start(){
  echo start
  str="$(grep '[[:alnum:]]' "${script_dir}/dbs.txt" | tail -n 1 | xargs)"
  stringarray=($str)
  source="${stringarray[0]}"
  port="${stringarray[1]}"
  sub_dir="default"
  pg_ctl="${psql_dir}/bin/pg_ctl"
  
  if [ -n "$port" ]; then
    sub_dir="${port}"
  fi
  
  ram_db="${ram_db_dir}/${sub_dir}"
  echo "start ${str}?"
  #echo -ne '' | nohup "${pg_ctl}" -D "${ram_db}" start & >/dev/null 2>&1 &
  nohup "${pg_ctl}" -D "${ram_db}" start &
  #echo "${pg_ctl} -D ${ram_db} start &" | at now
  
  read -p "Press a key"
}


function run(){
  init_vars
  sanity_check
  start
}


run
