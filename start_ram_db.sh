#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
psql_dir="$(cat "${DIR}/vars/psql_dir")"
ram_db_dir="$(cat "${DIR}/vars/ram_db_dir")"
_7za="$(cat "${DIR}/vars/7z_exec")"

str="$(grep '[[:alnum:]]' "${DIR}/dbs.txt" | tail -n 1 | xargs)"
stringarray=($str)
source="${stringarray[0]}"
port="${stringarray[1]}"
sub_dir="default"
pg_ctl="${psql_dir}/bin/pg_ctl"

if [ -n "$port" ]; then
  sub_dir="${port}"
fi

ram_db="${ram_db_dir}/${sub_dir}"
echo "start ${str}?"
#echo -ne '\n' | nohup "${pg_ctl}" -D "${ram_db}" start & >/dev/null 2>&1 &
nohup "${pg_ctl}" -D "${ram_db}" start &
#echo "${pg_ctl} -D ${ram_db} start &" | at now

read -p "Press a key"