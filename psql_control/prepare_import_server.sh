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
  echo "db_user: ${db_user}"
}


function prepare(){
  ram_db="${ram_db_dir}/7777"
  pg_ctl="${psql_dir}/bin/pg_ctl"
  init_db="${psql_dir}/bin/initdb"
  
  if [[ -d "${ram_db}" ]]; then
    set +e
    su - "${db_user}" -c "${pg_ctl} -D ${ram_db} stop  -m f"
    set -e
  fi
  
  rm -rf "${ram_db}"
  
  mkdir -p "${ram_db}"
  chmod 0700 "${ram_db}"
  chown "${db_user}" "${ram_db}"
  
  su - "${db_user}" -c "${init_db} -D ${ram_db} -E utf-8"
  sed -i 's/#port = 5432/port = 7777/g' "${ram_db}/postgresql.conf"
  su - "${db_user}" -c "${pg_ctl} -D ${ram_db} start"
}


function run(){
  init_vars
  sanity_check
  prepare
}


run
