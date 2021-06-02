#!/bin/bash

set -e
set -x

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

. "${script_dir}/helper_funcs.sh"


function init_vars() {
  echo init_vars
  import_vars_helper
}


function sanity_check() {
  echo sanity_check
  sanity_check_helper
  if [ ! -f "${path_db_meta}" ]; then
    read -p "db meta path not found: [${path_db_meta}]"
  fi
  echo "db_name: ${db_name}"
}


function restore() {
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
  read -p "Restore ${str}?"
  
  for line in "${lines[@]}"; do
    trimmed="$(echo $line | xargs)"
    if [ "${trimmed:0:1}" != "#" ]; then
      source="$(read_source_part "${line}")"
      pg_ver="$(read_version_part "${line}")"
      port="$(read_port_part "${line}")"
      pg_ctl="$(fetch_psql_dir "${pg_ver}")/bin/pg_ctl"
      this_db_name="$(read_name_part "${line}")"
      this_backup_path=""
      if [ "${backup_path}" = "" ]; then
        for path in "${backup_paths[@]}"; do
          temp="$(ls -1a "${path}" | sort -r | grep -E "^${this_db_name}__${pg_ver}__" | head -1)"
          if [ "${temp}" != "" ]; then
            this_backup_path="${path}/${temp}"
            break
          fi
        done
      else
        this_backup_path="${backup_path}"
      fi
      if [ ! -f "${this_backup_path}" ]; then
        echo "error restoring: not a file: ${this_backup_path}"
      else
        set +e
        su - "${db_user}" -c "${pg_ctl} -D ${source} stop -m f"
        set -e
        rm -rf "${source}"
    
        mkdir -p "${source}"
        chown "${db_user}" "${source}"
      
        su - "${db_user}" -c "${_7za} x -bsp1 ${this_backup_path} -aoa -o${source}"
      
        sed -i -E "s/#?port = .+/port = ${port}/" "${source}/postgresql.conf"
      
        chmod 0700 "${source}"
        chown "${db_user}" "${source}"
      
        su - "${db_user}" -c "${pg_ctl} -D ${source} start"
      fi
      
      
    fi
  done
  read -p "Restored ${db_name}"
}


function run() {
  db_name="$1"
  backup_path="$2"
  init_vars
  sanity_check
  restore
}


run "$@"
