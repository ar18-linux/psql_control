#!/usr/bin/env bash


function ar18.script._version_check(){


  function ar18.script.version_check() {
    # Function template 2021-06-12.01
    local LD_PRELOAD_old
    LD_PRELOAD_old="${LD_PRELOAD}"
    LD_PRELOAD=
    local shell_options
    IFS=$'\n' shell_options=($(shopt -op))
    set -eu
    set -o pipefail
    local ret
    ret=0
    set +x
    ##############################FUNCTION_START#################################
    
    ar18_version_checker_caller="$(caller | cut -d ' ' -f2-)"
    ar18_version_checker_caller="$(realpath "${ar18_version_checker_caller}")"
    ar18_version_checker_dir_name="$(dirname "${ar18_version_checker_caller}")"
    ar18_version_checker_module_name="$(basename "${ar18_version_checker_dir_name}")"
    if [ -f "${ar18_version_checker_dir_name}/VERSION" ]; then
      ar18_version_checker_module_version_local="$(cat "${ar18_version_checker_dir_name}/VERSION")"
      rm -f /tmp/VERSION
      wget "https://raw.githubusercontent.com/ar18-linux/${ar18_version_checker_module_name}/master/${ar18_version_checker_module_name}/VERSION" -P /tmp
      ar18_version_checker_module_version_remote="$(cat "/tmp/VERSION")"
      echo "local version is ${ar18_version_checker_module_version_local}"
      echo "remote version is ${ar18_version_checker_module_version_remote}"
      if [[ "${ar18_version_checker_module_version_remote}" > "${ar18_version_checker_module_version_local}" ]]; then
        echo "new version available"
        if [ -f "/home/$(whoami)/.config/${ar18_version_checker_module_name}/INSTALL_DIR" ]; then
          echo "reinstalling"
        else
          echo "replacing"
          rm -rf "/tmp/${ar18_version_checker_module_name}"
          mkdir -p "/tmp/${ar18_version_checker_module_name}"
          old_cwd="${PWD}"
          cd "/tmp/${ar18_version_checker_module_name}"
          git clone "http://github.com/ar18-linux/${ar18_version_checker_module_name}"
          cp -raf "/tmp/${ar18_version_checker_module_name}/${ar18_version_checker_module_name}/${ar18_version_checker_module_name}/." "${ar18_version_checker_dir_name}/"
          cd "${old_cwd}"
          . "${ar18_version_checker_caller}"
        fi
        # Return or exit depending on whether the script was sourced or not
        if [ "${ar18_sourced_map["${ar18_version_checker_caller}"]}" = "1" ]; then
          return "${ar18_exit_map["${ar18_version_checker_caller}"]}"
        else
          exit "${ar18_exit_map["${ar18_version_checker_caller}"]}"
        fi
      fi
      
    fi
    
    ###############################FUNCTION_END##################################
    set +x
    for option in "${shell_options[@]}"; do
      eval "${option}"
    done
    LD_PRELOAD="${LD_PRELOAD_old}"
    return "${ret}"
  }
  
   
}

type ar18.script.version_check > /dev/null 2>&1 || ar18.script._version_check
