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


function prepare(){
  set +e
  str="$(read_configuration "${db_name}" "${path_db_meta}")"
  set -e
  source="$(read_source_part "${str}")"
  port="$(read_port_part "${str}")"
  pg_ver="$(read_version_part "${str}")"
  pg_ctl="$(fetch_psql_dir "${pg_ver}")/bin/pg_ctl"
  init_db="$(fetch_psql_dir "${pg_ver}")/bin/initdb"
  
  read -p "init ${str}? ALL CURRENT DATA WILL BE LOST!!!"
  
  if [[ -d "${source}" ]]; then
    set +e
    su - "${db_user}" -c "${pg_ctl} -D ${source} stop  -m f"
    set -e
  fi
  
  rm -rf "${source}"
  
  mkdir -p "${source}"
  chmod 0700 "${source}"
  chown "${db_user}" "${source}"
  
  su - "${db_user}" -c "${init_db} -D ${source} -E utf-8"
  sed -i "s/#port = 5432/port = ${port}/g" "${source}/postgresql.conf"
  su - "${db_user}" -c "${pg_ctl} -D ${source} start"
}


function run(){
  db_name="$1"
  init_vars
  sanity_check
  prepare
}


run "$@"
