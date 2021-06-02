

function read_configuration() {
  local name="$1"
  local path_db_meta="$2"
  while IFS= read -r line; do
    if [ "$(echo "${line}" | grep -E "^${name}")" ]; then
      declare -a a_tokens
      a_tokens=($line)
      if [ "${a_tokens[0]}" = "${name}" ]; then
        echo "${line}"
        return 0
      fi
    fi
  done < "${path_db_meta}"
  return 1
}


function sanity_check_helper() {
  if [[ "$(whoami)" != "root" ]]; then
    read -p "not root"
    exit 1
  fi
  echo "_7za: ${_7za}"
  echo "psql_dirs:"
  for KEY in "${!psql_dirs[@]}"; do
    echo "${KEY}: ${psql_dirs[${KEY}]}"
  done
  echo "dump_path: ${dump_path}"
  echo "backup_paths:"
  for path in "${backup_paths[@]}"; do
    echo "${path}"
  done
  echo "db_user: ${db_user}"
}


function read_source_part() {
  local str="$1"
  local stringarray=($str)
  local source="${stringarray[1]}"
  source="${source%\"}"
  source="${source#\"}"
  if [ "${source}" = "" ]; then
    read -p "could not read source from ${str}"
    exit 1
  fi
  echo "${source}"
  return 0
}


function read_name_part() {
  local str="$1"
  local stringarray=($str)
  local ret="${stringarray[0]}"
  ret="${ret%\"}"
  ret="${ret#\"}"
  if [ "${ret}" = "" ]; then
    read -p "could not read name from ${str}"
    exit 1
  fi
  echo "${ret}"
  return 0
}


function read_port_part() {
  local str="$1"
  local stringarray=($str)
  local ret="${stringarray[2]}"
  if [ "${ret}" = "" ]; then
    read -p "could not read port from ${str}"
    exit 1
  fi
  echo "${ret}"
  return 0
}


function read_version_part() {
  local str="$1"
  local stringarray=($str)
  local ret="${stringarray[3]}"
  if [ "${ret}" = "" ]; then
    read -p "could not read version from ${str}"
    exit 1
  fi
  echo "${ret}"
  return 0
}


function generate_timestamp() {
  echo $(date '+%Y_%m_%d_%H_%M_%S')
}


function import_vars_helper() {
  if [ -f "/home/$(logname)/.config/ar18/psql_control/vars" ]; then
    . "/home/$(logname)/.config/ar18/psql_control/vars"
    path_db_meta="/home/$(logname)/.config/ar18/psql_control/dbs.txt"
  else
    . "${script_dir}/vars"
    path_db_meta="${script_dir}/dbs.txt"
  fi
}


function fetch_psql_dir() {
  pg_version="$1"
  ret="${psql_dirs["${pg_version}"]}"
  if [ "${ret}" = "" ]; then
    read -p "cannot find psql_dir for version [${pg_version}]"
    exit 1
  fi
  echo "${ret}"
  return 0
}
