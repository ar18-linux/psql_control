#!/usr/bin/env bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-09_20:12:35
  # Get old shell option values to restore later
  shopt -s inherit_errexit
  IFS=$'\n' shell_options=($(shopt -op))
  # Set shell options for this script
  set -o pipefail
  set -ex
  # Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
  LD_PRELOAD_old="${LD_PRELOAD}"
  set -u
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


function prepare(){
  set +e
  str="$(read_configuration "${db_name}" "${path_db_meta}")"
  set -e
  source="$(read_source_part "${str}")"
  port="$(read_port_part "${str}")"
  password="postgres"
  database="postgres"
  pg_ver="$(read_version_part "${str}")"
  pg_ctl="$(fetch_psql_dir "${pg_ver}")/bin/pg_ctl"
  my_psql="$(fetch_psql_dir "${pg_ver}")/bin/psql"
  init_db="$(fetch_psql_dir "${pg_ver}")/bin/initdb"
  
  if [ "${ask_for_confirmation}" = "1" ]; then
    read -p "init ${str}? ALL CURRENT DATA WILL BE LOST!!!"
    echo ""
  fi
  
  
  ar18.script.import script.execute_with_sudo
  
  if [[ -d "${source}" ]]; then
    set +e
    ar18.script.execute_with_sudo su - "${db_user}" -c "${pg_ctl} -D ${source} stop  -m f"
    set -e
  fi
  
  ar18.script.execute_with_sudo rm -rf "${source}"
  
  ar18.script.execute_with_sudo mkdir -p "${source}"
  ar18.script.execute_with_sudo chmod 0700 "${source}"
  ar18.script.execute_with_sudo chown "${db_user}:${db_user}" "${source}"
  
  ar18.script.execute_with_sudo su - "${db_user}" -c "${init_db} -D ${source} -E utf-8"
  ar18.script.execute_with_sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "${source}/postgresql.conf"
  ar18.script.execute_with_sudo sed -i "s/#port = 5432/port = ${port}/g" "${source}/postgresql.conf"
  ar18.script.execute_with_sudo su - "${db_user}" -c "echo \"host  all  all 0.0.0.0/0 md5\" >> ${source}/pg_hba.conf"
  
  ar18.script.execute_with_sudo su - "${db_user}" -c "${pg_ctl} -D ${source} start"
  ar18.script.execute_with_sudo chmod +x "${script_dir}/passwd.sh"
  ar18.script.execute_with_sudo su - "${db_user}" -c "${script_dir}/passwd.sh ${port} ${database} ${db_user} ${password} ${my_psql}"
}


function run(){
  db_name="$1"
  set +u
  ask_for_confirmation="${2}"
  set -u
  if [ "${ask_for_confirmation}" = "" ]; then
    ask_for_confirmation="1"
  fi
  export ask_for_confirmation="${ask_for_confirmation}"
  init_vars
  sanity_check
  prepare
}


run "$@"

##################################SCRIPT_END###################################
# Restore environment
{
  set +x
  # Restore LD_PRELOAD
  LD_PRELOAD="${LD_PRELOAD_old}"
  # Restore PWD
  cd "${ar18_pwd_map["${script_path}"]}"
  # Restore old shell values
  for option in "${shell_options[@]}"; do
    eval "${option}"
  done
}
# Return or exit depending on whether the script was sourced or not
{
  if [ "${ar18_sourced_map["${script_path}"]}" = "1" ]; then
    return "${ar18_exit_map["${script_path}"]}"
  else
    exit "${ar18_exit_map["${script_path}"]}"
  fi
}
