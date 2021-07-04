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

ar18.script.import script.version_check
ar18.script.version_check

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
  ar18.script.import ar18.script.execute_with_sudo
  ar18.script.import ar18.script.obtain_sudo_password
  
  ar18.script.obtain_sudo_password
  
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
    echo ""
    exit 1
  fi
  if [ "${ask_for_confirmation}" = "1" ]; then
    read -p "Backup ${str}?"
    echo ""
  fi
  
  if [ "${backup_path}" = "" ]; then
    backup_path="${backup_paths[0]}"
  fi
  mkdir -p "${backup_path}"
  ar18.script.execute_with_sudo chmod 0777 "${backup_path}" -R
  #echo "${ar18_sudo_password}" | sudo -Sk 
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
      ar18.script.execute_with_sudo su - "${db_user}" -c "${pg_ctl} -D ${source} stop -m f"
      #echo "${ar18_sudo_password}" | sudo -Sk 
      database_version="$(ar18.script.execute_with_sudo cat "${source}/PG_VERSION")"
      local ar18_error
      ar18_error=0
      set -e
      if [ "${database_version}" = "" ]; then
        ar18_error=1
        echo "failed to backup ${line}: could not determine version"
      else
        backup_name="${this_db_name}__${database_version}__${date}"
        path_db_7z="${backup_path}/${backup_name}.7z"
        
        echo "creating 7z archive..."
        ar18.script.execute_with_sudo "${_7za}" a -bsp1 "${path_db_7z}" "${source}/*" 
        #"${_7za}" a -bsp1 "${path_db_7z}" "${source}/*" 
        
        ar18.script.execute_with_sudo chmod 0777 "${path_db_7z}"
        #echo "${ar18_sudo_password}" | sudo -Sk chmod 0777 "${path_db_7z}"
        
        ar18.script.execute_with_sudo su - "${db_user}" -c "${pg_ctl} -D ${source} start"
        #echo "${ar18_sudo_password}" | sudo -Sk su - "${db_user}" -c "${pg_ctl} -D ${source} start"
      fi
    fi
  done
  if [ "${ar18_error}" = "0" ]; then
    if [ "${ask_for_confirmation}" = "1" ]; then
      read -p "Backed up ${str}, press a key"
    fi
  else
    read -p "Failed to back up ${str}"
    exit 1
  fi
}


function run(){
  db_name="$1"
  set +u
  backup_path="$2"
  ask_for_confirmation="${3}"
  set -u
  if [ "${ask_for_confirmation}" = "" ]; then
    ask_for_confirmation="1"
  fi
  init_vars
  sanity_check
  backup
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
