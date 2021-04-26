#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
psql_dir="$(cat "${DIR}/vars/psql_dir")"
ram_db_dir="$(cat "${DIR}/vars/ram_db_dir")"
_7za="$(cat "${DIR}/vars/7z_exec")"

pg_ctl="${psql_dir}/bin/pg_ctl"
init_db="${psql_dir}/bin/initdb"

#content="$(cat "${DIR}/dbs.txt" | xargs)"
#echo "g:${content}"
str="$(grep '[[:alnum:]]' "${DIR}/dbs.txt" | tail -n 1 | xargs)"
#str="$(sed -e '/^[<blank><tab>]*$/d' "${DIR}/dbs.txt" | sed -n -e '$p')"
#str="$(awk 'NF{p=$0}END{print p}' "${DIR}/dbs.txt")"
#echo "d${str}d"
#str="$(echo "${str}" | sed -e 's/^[ \t]*//')"
#echo "r${str}r"

stringarray=($str)
source="${stringarray[0]}"
port="${stringarray[1]}"
sub_dir="default"
#echo "w${port}w"
if [ -n "$port" ]; then
  sub_dir="$(echo "${port}" | xargs)"
fi

ram_db="${ram_db_dir}/${sub_dir}"

#echo "w${str}w"
#echo "w${ram_db}w"
#echo "w${sub_dir}w"
#printf '%s\n' "${stringarray[@]}"
#echo "${pg_ctl} -D ${ram_db} stop -m f"
read -p "stop ${str}?"

"${pg_ctl}" -D "${ram_db}" stop -m f

read -p "Press a key"