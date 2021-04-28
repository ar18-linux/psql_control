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


function restore(){
  pg_ctl="${psql_dir}/bin/pg_ctl"
  str="$(grep '[[:alnum:]]' "${script_dir}/dbs.txt" | tail -n 1 | xargs)"
  stringarray=($str)
  source="${stringarray[0]}"
  port="${stringarray[1]}"
  sub_dir="default"
  
  if [ -n "$port" ]; then
    sub_dir="${port}"
  fi
  
  ram_db="${ram_db_dir}/${sub_dir}"
  
  read -p "restore ${str}?"
  
  #pid=$(head -1 "${ram_db}/postmaster.pid")
  #taskkill //F //PID $pid || /bin/kill -INT $pid || "${pg_ctl}" -D "${ram_db}" stop
  set +e
  su - "${db_user}" -c "${pg_ctl} -D ${ram_db} stop -m f"
  set -e
  #echo waiting 10 secs...
  #sleep 10
  
  rm -rf "${ram_db}"
  
  mkdir "${ram_db}"
  chown "${db_user}" "${ram_db}"
  
  su - "${db_user}" -c "${_7za} x -bsp1 ${target}/${source}.7z -aoa -o${ram_db}" 
  
  if [ -n "$port" ]; then
    sed -i -E "s/#?port = .+/port = ${port}/" "${ram_db}/postgresql.conf"
    #chown "${db_user}" "${ram_db}/postgresql.conf"
  fi
  
  chmod 0700 "${ram_db}"
  chown "${db_user}" "${ram_db}"
  
  echo "restored ${source}"
  echo "Press a key"
  su - "${db_user}" -c "${pg_ctl} -D ${ram_db} start"
  #nohup su - "${db_user}" -c "${pg_ctl} -D ${ram_db} start" &
}


function run(){
  init_vars
  sanity_check
  restore
}


run

