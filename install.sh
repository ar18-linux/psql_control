#!/bin/bash

set -e

if [[ "$(whoami)" != "root" ]]; then
  read -p "[ERROR] must be root!"
  exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

. "${script_dir}/vars"

mkdir -p "${install_dir}"

rm -rf "${install_dir}/${module_name}"
cp -rf "${script_dir}/${module_name}" "${install_dir}/${module_name}"
chmod +x "${install_dir}/${module_name}/"* -R

mkdir -p "/home/${user_name}/.config/ar18/${module_name}"
chown "${user_name}:${user_name}" "/home/${user_name}/.config/ar18/${module_name}"

if [ ! -f "/home/${user_name}/.config/ar18/${module_name}/dbs.txt" ]; then
  cp "${script_dir}/${module_name}/dbs.txt" "/home/${user_name}/.config/ar18/${module_name}/dbs.txt"
  chown "${user_name}:${user_name}" "/home/${user_name}/.config/ar18/${module_name}/dbs.txt"
fi

if [ ! -f "/home/${user_name}/.config/ar18/${module_name}/vars" ]; then
  cp "${script_dir}/${module_name}/vars" "/home/${user_name}/.config/ar18/${module_name}/vars"
  chown "${user_name}:${user_name}" "/home/${user_name}/.config/ar18/${module_name}/vars"
fi
