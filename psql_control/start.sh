#!/usr/bin/env bash
# ar18

# Prepare script environment
{
  # Script template version 2021-07-06_08:05:30
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


function start(){
  echo start
  ar18.script.import script.obtain_sudo_password
  ar18.script.obtain_sudo_password
  echo "${ar18_sudo_password}" | sudo -Sk mkdir -p /run/postgresql
  echo "${ar18_sudo_password}" | sudo -Sk chown "${db_user}:${db_user}" /run/postgresql
  if [ "${db_name}" = "" ]; then
    str="$(grep '[[:alnum:]]' "${path_db_meta}" | tail -n 1 | xargs)"
    declare -A lines
    lines[0]=str
  elif [ "${db_name}" = "all" ]; then
    IFS=$'\r\n' GLOBIGNORE='*' command eval "lines=(\$(cat "${path_db_meta}"))"
    str="${db_name}"
  else
    set +e
    str="$(cat "${path_db_meta}" | grep -E "^[\"\']?${db_name}")"
    set -e
    declare -A lines
    lines[0]="${str}"
  fi
  if [ "${lines[0]}" = "" ]; then
    read -p "db not found: [${db_name}]"
    echo ""
    exit 1
  fi
  read -p "start ${str}?"
  echo ""
  errors=0
  for line in "${lines[@]}"; do
    trimmed="$(echo $line | xargs)"
    if [ "${trimmed:0:1}" != "#" ]; then
      source="$(read_source_part "${line}")"
      pg_ver="$(read_version_part "${line}")"
      pg_ctl="$(fetch_psql_dir "${pg_ver}")/bin/pg_ctl"
      pid=-1
      if [ -f "${source}/postmaster.pid" ]; then
        pid="$(cat "${source}/postmaster.pid" | head -1)"
        echo "${ar18_sudo_password}" | sudo -Sk kill -0 "${pid}" || pid=-1
      fi
      set +e
      if [ "${pid}" = "-1" ]; then
        echo "${ar18_sudo_password}" | sudo -Sk su - "${db_user}" -c "${pg_ctl} -D ${source} start"
        ret=$?
        if [ "${ret}" != "0" ]; then
          echo "failed to start ${line}" >&2
          echo ""
          errors=$((errors + 1))
        else
          echo "started ${source}"
          echo ""
        fi
      else
        echo "already started: ${source}"
        echo ""
      fi
      set -e
    fi
  done
  if [ "${errors}" != "0" ]; then
    read -p "Failed to start some entries, press a key"
    echo ""
  else
    read -p "Started ${str}, press a key"
    echo ""
  fi
}


function run(){
  db_name="$1"
  init_vars
  sanity_check
  start
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
