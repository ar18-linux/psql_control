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


function stop(){
  echo stop
  pg_ctl="${psql_dir}/bin/pg_ctl"
  init_db="${psql_dir}/bin/initdb"
  
  #content="$(cat "${DIR}/dbs.txt" | xargs)"
  #echo "g:${content}"
  str="$(grep '[[:alnum:]]' "${DIR}/dbs.txt" | tail -n 1 | xargs)"
  #str="$(sed -e '/^[<blank><tab>]*$/d' "${DIR}/dbs.txt" | sed -n -e '$p')"
  #str="$(awk 'NF{p=$0}END{print p}' "${DIR}/dbs.txt")"
  #echo "d${str}d"
  #str="$(echo "${str}" | sed -e 's/^[ 	]*//')"
  #echo "r${str}r"
  
  stringarray=($str)
  source="${stringarray[0]}"
  port="${stringarray[1]}"
  sub_dir="default"
  #echo "w${port}w"
  if [ -n "$port" ]; then
    sub_dir="$(echo "${port}" | xargs)"
  fi
  
  ram_db="${ram_db_dir}/${sub_dir}"
  
  #echo "w${str}w"
  #echo "w${ram_db}w"
  #echo "w${sub_dir}w"
  #printf '%s' "${stringarray[@]}"
  #echo "${pg_ctl} -D ${ram_db} stop -m f"
  read -p "stop ${str}?"
  
  "${pg_ctl}" -D "${ram_db}" stop -m f
  
  read -p "Press a key"
}


function run(){
  init_vars
  sanity_check
  restore
}


run
