#!/usr/bin/env bash
# By:    elmauromx
# Usage: stub.bash command arg1 arg2 \"sub_arg1 subarg2\" ... ${argn}
# Description:  Script for stubbing commands for testing processess.
#               _ When running for the very first time, make sure to execute
#               _ . $HOME/.bash_profile in order to prepend .binstub dir
#               _ to $PATH and new stub commands are preferred
#
#               _ When executing stub commands, make sure to escape " characters
#               _ for example, to add multiple word arguments to stub like:
#               _        ./stub.bash date \"+%Y%m%d %H%M%S\"
#               _ stubbed command must be invoked like:
#               _        date \"+%Y%m%d %H%M%S\"
#               _
#               _ Commands will not be properly stubbed if " characters are NOT
#               _ escaped with \
#               _ Commands and arguments are hashed with sha in order to
#               _ record them on cache. In the case you change parameter order
#               _ or add spaces on args, commands will not match and stubbed
#               _ command will not be executed but original command instead

# function: usage
usage () {
  echo "${0} \$arg1 \$arg2 \\\"sub_arg1 sub_arg2\\\"... argn"
}

get_hash_command(){
  hash_command_list="shasum shasum1"
  hash_command_array=(${hash_command_list})
  for item in "${hash_command_array[@]}"; do
    [[ $(command -v "${item}") ]] && { hash_cmd="${item}"; break; }
  done
  [[ ! ${hash_cmd} ]] && { echo "No comand: """${hash_command_list}""" found"; exit 1; }
  echo "${item}"
}

# function: Stub program
unstub_command() {
  cmd_to_run="$(cat $1)"
  cmd_to_run_noargs="$(echo """${cmd_to_run}""" | awk '{print $1}')"
  # Gets full path for cmd to run without arguments
  full_path_cmd_to_run="$(command -v $(echo ${cmd_to_run} | awk '{print $1}') )"

  ## declare and create script files and dirs
  binstubs_dir=".binstub"
  filestubs_dir=".stubfiles"
  mkdir -p "${binstubs_dir}"
  mkdir -p "${filestubs_dir}"

  ## Get Hash utility
  hash_cmd="$(get_hash_command)"

  ## Get hash for cmd_to_run without arguments
  cmd_to_run_hash="$(echo "${cmd_to_run}" | "${hash_cmd}" | awk '{print $1}')"
  cmd_to_run_noargs_hash="$(echo "${cmd_to_run_noargs}" | "${hash_cmd}" | awk '{print $1}')"

  ## Generate files

  cache_file="${filestubs_dir}/.stub.cache.tmp"
  cache_cmd="${filestubs_dir}/.stub.cachecmd.tmp"
  stderr_file="${filestubs_dir}/.stub.stderr.${cmd_to_run_hash}.tmp"
  stdout_file="${filestubs_dir}/.stub.stdout.${cmd_to_run_hash}.tmp"
  origcmd_file="${filestubs_dir}/.stub.origcmd.${cmd_to_run_hash}.tmp"

  ## Copy original Command
  #cp $1 "${origcmd_file}"
  #chmod 755 "${origcmd_file}"
  ## if cache file does not exist create it
  [[ ! -f ${cache_file} ]] && { touch "${cache_file}" ; }
  [[ ! -f ${cache_cmd} ]] && { touch "${cache_cmd}" ; }

  ## Determines whether cmd_to_run with arguments hash exists on cache
  grep -q "${cmd_to_run_hash}" "${cache_file}"
  is_hash_cached=$?

  ###echo "${cache_file}:${is_hash_cached} "

  if [ "${is_hash_cached}" == "0"  ]; then

     ## Run command with arguments and saves stderr, stdout and return code
     echo "------------------Stubbed Command------------------"
     echo "Command:       """$(cat ${origcmd_file})""""
     ${origcmd_file} 2>${stderr_file} 1>${stdout_file}
     cmd_retcode=$?

     echo "Return Code:   """${cmd_retcode}""""
     echo "------------------- STDOUT ------------------------"
     cat  "${stdout_file}"
     echo "------------------- STDOUT ------------------------"
     ##alias_cmd="$(echo ${cmd_to_run} | awk '{print $1}')"
     stub_cmd_launcher=".stub_cmd_launcher.bash"

     echo "------------------- STDERR ------------------------"
     cat  "${stderr_file}"
     echo "------------------- STDERR ------------------------"
     echo ""
     echo "Removing origcmd file:         """${origcmd_file}""""
     echo "Removing stdout file:          """${stdout_file}""""
     echo "Removing stderr file:          """${stderr_file}""""

     ## Delete entry from cache

     grep -v "${cmd_to_run_hash}" "${cache_file}" > "${cache_file}.tmp"
     cat "${cache_file}.tmp" > "${cache_file}"
     rm ${cache_file}.tmp

     # Validates if command (with other arguments) still exists in cache
     grep -q ${cmd_to_run_noargs} ${cache_file}
     is_cmd_hash_cached=$?

     if [[ "${is_cmd_hash_cached}" != "0" ]]; then
       ## Delete entry from command without args cache
       grep -q ${cmd_to_run_noargs_hash} ${cache_cmd}
       is_cmd_hash_cached=$?

       if [[ "${is_cmd_hash_cached}" == "0" ]]; then
         grep -v "${cmd_to_run_noargs_hash}" "${cache_cmd}" > "${cache_cmd}.tmp"

         cat "${cache_cmd}.tmp" > "${cache_cmd}"
         #echo "Removing link file:            """${binstubs_dir}"""/"""${cmd_to_run_noargs}""""
         #rm "${binstubs_dir}"/"${cmd_to_run_noargs}"
       fi
     fi

     rm "${stdout_file}"
     rm "${stderr_file}"

     echo "---------------------------------------------------"
     echo "Successfully removed \""""$(cat ${origcmd_file})"""\" from stub cache"
     rm "${origcmd_file}"
  else
    echo "NO \"${cmd_to_run}\" command found on cache"
    exit 1
  fi

}


while getopts ":h" arg; do
  case $arg in
    a)
      delete_all="Y"
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

input_cmd=".stub.cmd.tmp"
echo "${@}" > "${input_cmd}"

[[ ! ${input_cmd}  ]] && { usage; exit 1; }

unstub_command "${input_cmd}" "${delete_all}"

rm "${input_cmd}"
