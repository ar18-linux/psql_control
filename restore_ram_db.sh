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

ram_db="${ram_db_dir}/${sub_dir}"

read -p "restore ${str}?"

pid=$(head -1 "${ram_db}/postmaster.pid")
#taskkill //F //PID $pid || /bin/kill -INT $pid || "${pg_ctl}" -D "${ram_db}" stop
"${pg_ctl}" -D "${ram_db}" stop -m f
#echo waiting 10 secs...
#sleep 10

rm -rf "${ram_db}"

mkdir "${ram_db}"

"${_7za}" x -bsp1 "${target}/${source}.7z" -aoa -o"${ram_db}" 

if [ -n "$port" ]; then
  sed -i -E "s/#?port = .+/port = ${port}/" "${ram_db}/postgresql.conf"
fi

chmod 0700 "${ram_db}"

echo "restored ${source}"
echo "Press a key"
nohup "${pg_ctl}" -D "${ram_db}" start &