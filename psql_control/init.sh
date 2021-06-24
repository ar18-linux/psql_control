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
  my_psql="$(fetch_psql_dir "${pg_ver}")/bin/psql"
  init_db="$(fetch_psql_dir "${pg_ver}")/bin/initdb"
  
  if [ "${ask_for_confirmation}" = "1" ]; then
    read -p "init ${str}? ALL CURRENT DATA WILL BE LOST!!!"
  fi
  
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
  sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "${source}/postgresql.conf"
  sed -i "s/#port = 5432/port = ${port}/g" "${source}/postgresql.conf"
  su - "${db_user}" -c "echo \"host  all  all 0.0.0.0/0 md5\" >> ${source}/pg_hba.conf"
  
  su - "${db_user}" -c "${pg_ctl} -D ${source} start"
  su - "${db_user}" -c "${my_psql} -p ${port} -d postgres -c \"ALTER USER ${db_user} PASSWORD 'postgres';\""
}


function run(){
  db_name="$1"
  ask_for_confirmation="${2}"
  if [ "${ask_for_confirmation}" = "" ]; then
    ask_for_confirmation="1"
  fi
  export ask_for_confirmation="${ask_for_confirmation}"
  init_vars
  sanity_check
  prepare
}


run "$@"
