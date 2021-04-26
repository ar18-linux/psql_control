#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
psql_dir="$(cat "${DIR}/vars/psql_dir")"
ram_db_dir="$(cat "${DIR}/vars/ram_db_dir")"
_7za="$(cat "${DIR}/vars/7z_exec")"

ram_db="${ram_db_dir}/7777"
pg_ctl="${psql_dir}/bin/pg_ctl"
init_db="${psql_dir}/bin/initdb"

"${pg_ctl}" -D "${ram_db}" stop  -m f

rm -rf "${ram_db}"

mkdir "${ram_db}"

"${init_db}" -D "${ram_db}" -E utf-8
sed -i 's/#port = 5432/port = 7777/g' "${ram_db}/postgresql.conf"
"${pg_ctl}" -D "${ram_db}" start
