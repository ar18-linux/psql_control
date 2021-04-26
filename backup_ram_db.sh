#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
psql_dir="$(cat "${DIR}/vars/psql_dir")"
ram_db_dir="$(cat "${DIR}/vars/ram_db_dir")"
target="$(cat "${DIR}/vars/zip_dir")"
_7za="$(cat "${DIR}/vars/7z_exec")"
pg_ctl="${psql_dir}/bin/pg_ctl"

str="$(grep '[[:alnum:]]' "${DIR}/dbs.txt" | tail -n 1 | xargs)"
stringarray=($str)
source="${stringarray[0]}"
port="${stringarray[1]}"
sub_dir="default"

if [ -n "$port" ]; then
  sub_dir="${port}"
fi

date="$(date '+%Y_%m_%d_%H_%M')"

ram_db="${ram_db_dir}/${sub_dir}"

pid=$(head -1 "${ram_db}/postmaster.pid")

read -p "backup ${ram_db}?"
"${pg_ctl}" -D "${ram_db}" stop -m f

echo "creating 7z archive..."
"${_7za}" a -bsp1 "${target}/local_${date}.7z" "${ram_db}/*" 

"${pg_ctl}" -D "${ram_db}" start

echo "backed up as ${date}.7z"
read -p "Press a key"