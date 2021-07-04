#!/bin/bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-04_17:50:00
  # Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
  LD_PRELOAD_old="${LD_PRELOAD}"
  LD_PRELOAD=
  # Determine the full path of the directory this script is in
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  script_path="${script_dir}/$(basename "${0}")"
  #Set PS4 for easier debugging
  export PS4='\e[35m${BASH_SOURCE[0]}:${LINENO}: \e[39m'
  # Determine if this script was sourced or is the parent script
  if [ ! -v ar18_sourced_map ]; then
    declare -A -g ar18_sourced_map
  fi
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    ar18_sourced_map["${script_path}"]=1
  else
    ar18_sourced_map["${script_path}"]=0
  fi
  # Initialise exit code
  if [ ! -v ar18_exit_map ]; then
    declare -A -g ar18_exit_map
  fi
  ar18_exit_map["${script_path}"]=0
  # Save PWD
  if [ ! -v ar18_pwd_map ]; then
    declare -A -g ar18_pwd_map
  fi
  ar18_pwd_map["${script_path}"]="${PWD}"
  # Get old shell option values to restore later
  shopt -s inherit_errexit
  IFS=$'\n' shell_options=($(shopt -op))
  # Set shell options for this script
  set -o pipefail
  set -eu
  if [ ! -v ar18_parent_process ]; then
    export ar18_parent_process="$$"
  fi
  # Get import module
  if [ ! -v ar18.script.import ]; then
    mkdir -p "/tmp/${ar18_parent_process}"
    cd "/tmp/${ar18_parent_process}"
    curl -O https://raw.githubusercontent.com/ar18-linux/ar18_lib_bash/master/ar18_lib_bash/script/import.sh > /dev/null 2>&1 && . "/tmp/${ar18_parent_process}/import.sh"
    cd "${ar18_pwd_map["${script_path}"]}"
  fi
}
#################################SCRIPT_START##################################

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
  ar18.script.import ar18.script.execute_with_sudo
  ar18.script.import ar18.script.obtain_sudo_password
  
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
  
  ar18.script.obtain_sudo_password
  
  ar18.script.execute_with_sudo mkdir -p /run/postgresql
  ar18.script.execute_with_sudo chown "${db_user}:${db_user}" /run/postgresql
  
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
        ar18.script.execute_with_sudo su - "${db_user}" -c "${pg_ctl} -D ${source} stop -m f"
        set -e
        ar18.script.execute_with_sudo rm -rf "${source}"
    
        ar18.script.execute_with_sudo mkdir -p "${source}"
        ar18.script.execute_with_sudo chown "${db_user}:${db_user}" "${source}"
      
        ar18.script.execute_with_sudo su - "${db_user}" -c "${_7za} x -bsp1 ${this_backup_path} -aoa -o${source}"
      
        ar18.script.execute_with_sudo sed -i -E "s/#?port = .+/port = ${port}/" "${source}/postgresql.conf"
      
        ar18.script.execute_with_sudo chmod 0700 "${source}"
        ar18.script.execute_with_sudo chown "${db_user}:${db_user}" "${source}"
      
        ar18.script.execute_with_sudo su - "${db_user}" -c "${pg_ctl} -D ${source} start"
      fi
    fi
  done
  read -p "Restored ${db_name}"
}


function run() {
  db_name="$1"
  set +u
  backup_path="$2"
  set -u
  init_vars
  sanity_check
  restore
}


run "$@"

##################################SCRIPT_END###################################
# Restore environment
{
  # Restore old shell values
  set +x
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
  # Restore LD_PRELOAD
  LD_PRELOAD="${LD_PRELOAD_old}"
  # Restore PWD
  cd "${ar18_pwd_map["${script_path}"]}"
}
# Return or exit depending on whether the script was sourced or not
{
  if [ "${ar18_sourced_map["${script_path}"]}" = "1" ]; then
    return "${ar18_exit_map["${script_path}"]}"
  else
    exit "${ar18_exit_map["${script_path}"]}"
  fi
}
