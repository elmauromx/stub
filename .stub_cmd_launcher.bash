#!/usr/bin/env bash
# By:    elmauromx

get_hash_command(){
  hash_command_list="shasum shasum1"
  hash_command_array=(${hash_command_list})
  for item in "${hash_command_array[@]}"; do
    [[ $(command -v "${item}") ]] && { hash_cmd="${item}"; break; }
  done
  [[ ! ${hash_cmd} ]] && { echo "No comand: """${hash_command_list}""" found"; exit 1; }
  echo "${item}"
}

run_stub_command(){
  cmd_to_run="$(cat $1)"
  ## declare and create script files and dirs
  binstubs_dir=".binstub"
  filestubs_dir=".stubfiles"

  hash_cmd="$(get_hash_command)"

  cache_file="${filestubs_dir}/.stub.cache.tmp"
  cache_cmd="${filestubs_dir}/.stub.cachecmd.tmp"

  ## Gets Command hashed (including parameters)
  cmd_to_run_hash="$(echo "${cmd_to_run}" | "${hash_cmd}" | awk '{print $1}')"
  hash_line="$(grep  """${cmd_to_run_hash}""" """${cache_file}""" | head -1)"

  if [ "${hash_line}" ]; then
     ## Return STDOUT, STDERR and arguments
    stdout_file="$(echo """${hash_line}"""  | sed """s/:/ /g""" | awk '{print $4}')"
    stderr_file="$(echo """${hash_line}"""  | sed """s/:/ /g""" | awk '{print $5}')"
    cmd_retcode="$(echo """${hash_line}"""  | sed """s/:/ /g""" | awk '{print $3}')"
    cat "${stdout_file}"
    [[ -s "${stderr_file}" ]] && { cat "${stderr_file}" > @2 ; }
    ###echo "no run"
    rm -f $1
    exit "${cmd_retcode}"
  else
    hash_line="$(grep """${cmd_to_run_noargs_hash}""" """${cache_cmd}""" | head -1)"
    rm -f $1
    if [[ "${hash_line}" ]]; then
       stubcmd_to_run="$(echo """${hash_line}"""  | sed """s/:/ /g""" | awk '{print $3}')"
       stubcmd_to_run_path="${stubcmd_to_run%/*}"
       ###echo """"${stubcmd_to_run_path}"""/"""${cmd_to_run}""""
       eval """"${stubcmd_to_run_path}"""/"""${cmd_to_run}""""
       ###echo "run"
    else
       echo "Error. No recorded full path command for """${cmd_to_run_noargs_hash}""" found. "
       exit 1
    fi
  fi

}

stub_command="$(basename $0) $*"
stub_command_file=".stub_command_file.tmp.$$"
echo "${stub_command}" > "${stub_command_file}"

run_stub_command "${stub_command_file}"
rm -f "${stub_command_file}"
