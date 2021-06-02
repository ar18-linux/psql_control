#!/bin/bash

set -x
set -e

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


function backup(){
  echo backup
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
  read -p "Backup ${str}?"
  if [ "${backup_path}" = "" ]; then
    backup_path="${backup_paths[0]}"
  fi
  mkdir -p "${backup_path}"
  chmod 0777 "${backup_path}" -R
  for line in "${lines[@]}"; do
    trimmed="$(echo $line | xargs)"
    if [ "${trimmed:0:1}" != "#" ]; then
      stringarray=($trimmed)
      source="$(read_source_part "${line}")"
      pg_ver="$(read_version_part "${line}")"
      pg_ctl="$(fetch_psql_dir "${pg_ver}")/bin/pg_ctl"
      this_db_name="$(read_name_part "${line}")"
  
      date="$(generate_timestamp)"
      set +e
      su - "${db_user}" -c "${pg_ctl} -D ${source} stop -m f"
      database_version="$(cat "${source}/PG_VERSION")"
      set -e
      if [ "${database_version}" = "" ]; then
        echo "failed to backup ${line}: could not determine version"
      else
        backup_name="${this_db_name}__${database_version}__${date}"
        path_db_7z="${backup_path}/${backup_name}.7z"
        
        echo "creating 7z archive..."
        "${_7za}" a -bsp1 "${path_db_7z}" "${source}/*" 
        
        chmod 0777 "${path_db_7z}"
        
        su - "${db_user}" -c "${pg_ctl} -D ${source} start"
      fi
      
      
    fi
  done
  
  read -p "Backed up ${str}, press a key"
}


function run(){
  db_name="$1"
  backup_path="$2"
  init_vars
  sanity_check
  backup
}


run "$@"
