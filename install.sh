#!/bin/bash

set -e

if [[ "$(whoami)" != "root" ]]; then
  read -p "[ERROR] must be root!"
  exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

. "${script_dir}/vars"

if [ ! -d "${install_dir}" ]; then
  mkdir -p "${install_dir}"
fi

rm -rf "${install_dir}/${module_name}"
cp -rf "${script_dir}/${module_name}" "${install_dir}/${module_name}"
chmod +x "${install_dir}/${module_name}/"* -R

mkdir -p "/home/$(logname)/.config/ar18/psql_control"
chown "$(logname):$(logname)" "/home/$(logname)/.config/ar18/psql_control"

if [ ! -f "/home/$(logname)/.config/ar18/psql_control/dbs.txt" ]; then
  echo "# Last value is picked up." > "/home/$(logname)/.config/ar18/psql_control/dbs.txt"
fi

if [ ! -f "/home/$(logname)/.config/ar18/psql_control/vars" ]; then
  cp "${script_dir}/${module_name}/vars" "/home/$(logname)/.config/ar18/psql_control/vars"
  chown "$(logname):$(logname)" "/home/$(logname)/.config/ar18/psql_control/vars"
fi
