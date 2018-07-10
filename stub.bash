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
  hash_command_array=(shasum shasum1)
  for item in "${hash_command_array[@]}" ; do
    [[ $(command -v "${item}") ]] && { hash_cmd="${item}"; break; }
  done
  echo "${hash_cmd}"
}

# function: Stub program
stub_command() {
  cmd_to_run="$(cat """$1""")"
  cmd_to_run_noargs="$(echo """${cmd_to_run}""" | awk '{print $1}')"
  # Gets full path for cmd to run without arguments
  full_path_cmd_to_run="$(command -v """$(echo """${cmd_to_run}""" | awk '{print $1}')""" )"

  ## declare and create script files and dirs
  binstubs_dir=".binstub"
  filestubs_dir=".stubfiles"
  mkdir -p "${binstubs_dir}"
  mkdir -p "${filestubs_dir}"

  ## chech for ~/.bash_profile file
  env_home="$(ls -d ~)"
  [[ ! -f "${env_home}/.bash_profile" ]] && { echo "" >> "${env_home}/.bash_profile" ; }

  ## Chech for binstub dir at the first of the path
  env_path="$(grep "${binstubs_dir}" "${env_home}/.bash_profile" | tail -1 | sed "s/export //g" | sed "s/PATH=//g" | sed "s/:/ /g" | awk '{print $1}')"

  ##echo "$env_profile:$env_path:pelos"

  if [ "${env_path}" != "${binstubs_dir}" ]; then
     {
     echo ""
     echo "## Added by stub.bash"
     echo "export PATH=${binstubs_dir}:.:\$PATH"
   }  >> "${env_home}/.bash_profile"

    echo "-------------- IMPORTANT ------------------"
    echo "stub.bash ran for the first time. Don't forget to run ." "${env_home}/.bash_profile"
    echo "or disconnect and reconnect in orden prepend path for binstub applies."
    echo "-------------------------------------------"
  fi

  ## Get Hash utility
  hash_cmd="$(get_hash_command)"
  if [[ ! ${hash_cmd} ]]; then
     echo "No comand shasum or sha1sum found"
     exit 1
  fi

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
  cp "$1" "${origcmd_file}"
  chmod 755 "${origcmd_file}"
  ## if cache file does not exist create it
  [[ ! -f ${cache_file} ]] && { touch "${cache_file}" ; }
  [[ ! -f ${cache_cmd} ]] && { touch "${cache_cmd}" ; }

  ## Determines whether cmd_to_run with arguments hash exists on cache
  grep -q "${cmd_to_run_hash}" "${cache_file}"
  is_hash_cached=$?

  ###echo "${cache_file}:${is_hash_cached} "

  if [ "${is_hash_cached}" != "0"  ]; then

     ## Run command with arguments and saves stderr, stdout and return code

     echo "Command:       \"$(cat """${origcmd_file}""")\""
     "${origcmd_file}" 2>"${stderr_file}" 1>"${stdout_file}"
     cmd_retcode=$?

     echo "Return Code:   \"${cmd_retcode}\""
     echo "------------------- STDOUT ------------------------"
     cat  "${stdout_file}"
     echo "------------------- STDOUT ------------------------"
     ##alias_cmd="$(echo ${cmd_to_run} | awk '{print $1}')"
     stub_cmd_launcher=".stub_cmd_launcher.bash"

     echo "------------------- STDERR ------------------------"
     cat  "${stderr_file}"
     echo "------------------- STDERR ------------------------"

     ## Record cmd_to_run on cache
     ## Parameters:
     ##    1. Original Command hash
     ##    2. Original Command File
     ##    3. Return code
     ##    4. STDOUT file
     ##    5. STDERR files
     echo "${cmd_to_run_hash}:${origcmd_file}:${cmd_retcode}:${stdout_file}:${stderr_file}:${full_path_cmd_to_run}" >> ${cache_file}

     ## Record cmd_to_run_noargs on cache
     ## Parameters:
     ##    1. Original Command noargs hash
     ##    2. Original Command noargs
     ##    3. Full Path Original Command
     grep -q "${cmd_to_run_noargs_hash}" "${cache_cmd}"
     is_cmd_hash_cached=$?

     if [[ "${is_cmd_hash_cached}" != "0" ]]; then
        echo "${cmd_to_run_noargs_hash}:${cmd_to_run_noargs}:${full_path_cmd_to_run}:" >> ${cache_cmd}
     fi

     echo "Successfully added \"$(cat """${origcmd_file}""")\" to stub cache"

     ## In case link for command does not exist yet
     if [[ ! -f "${binstubs_dir}/${cmd_to_run_noargs}" ]]; then
       cd "${binstubs_dir}" || exit 1
       ln -s "../${stub_cmd_launcher}" "${cmd_to_run_noargs}"
       cd - >/dev/null 2>&1 || exit 1
     fi
  fi

}


while getopts ":h" arg; do
  case $arg in
    h)
      usage
      exit 1
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

stub_command "${input_cmd}"

rm "${input_cmd}"
