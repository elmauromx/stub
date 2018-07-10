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

# function: Stub program
stub_command() {
  cmd_to_run="$(cat $1)"
  cmd_to_run_noargs="$(echo """${cmd_to_run}""" | awk '{print $1}')"
  # Gets full path for cmd to run without arguments
  full_path_cmd_to_run="$(command -v $(echo ${cmd_to_run} | awk '{print $1}') )"
  cache_space="##__##"

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
     echo "## Added by stub.sh"
     echo "export PATH=${binstubs_dir}:.:\$PATH"
   }  >> "${env_home}/.bash_profile"

    . "${env_home}/.bash_profile"
  fi

  ## Get Hash utility
  hash_cmd=""
  [[ $(command -v shasum) ]] && { hash_cmd="shasum"; }
  [[ $(command -v sha1sum) ]] && { hash_cmd="sha1sum"; }
  [[ ! ${hash_cmd} ]] && { echo "No sha1sum or shasum found"; exit 1; }

  ## Get hash for cmd_to_run without arguments
  cmd_to_run_hash="$(echo "${cmd_to_run}" | "${hash_cmd}" | awk '{print $1}')"
  cmd_to_run_noargs_hash="$(echo "${cmd_to_run_noargs}" | "${hash_cmd}" | awk '{print $1}')"

  ## Generate files

  cache_file="${filestubs_dir}/.stub.cache.tmp"
  stderr_file="${filestubs_dir}/.stub.stderr.${cmd_to_run_hash}.tmp"
  stdout_file="${filestubs_dir}/.stub.stdout.${cmd_to_run_hash}.tmp"
  origcmd_file="${filestubs_dir}/.stub.origcmd.${cmd_to_run_hash}.tmp"

  ## Copy original Command
  cp $1 "${origcmd_file}"
  chmod 755 "${origcmd_file}"
  ## if cache file does not exist create it
  [[ ! -f ${cache_file} ]] && { touch "${cache_file}" ; }

  ## Determines whether cmd_to_run with arguments hash exists on cache
  grep -q ${cmd_to_run_hash} ${cache_file}
  is_hash_cached=$?

  ###echo "${cache_file}:${is_hash_cached} "

  if [ "${is_hash_cached}" != "0"  ]; then

     ## Run command with arguments and saves stderr, stdout and return code

     echo "Command:       """$(cat ${origcmd_file})""""
     ${origcmd_file} 2>${stderr_file} 1>${stdout_file}
     cmd_retcode=$?

     echo "Return Code:   """${cmd_retcode}""""
     echo "------------------- STDOUT ------------------------"
     cat  "${stdout_file}"
     echo "------------------- STDOUT ------------------------"
     alias_cmd="$(echo ${cmd_to_run} | awk '{print $1}')"

     echo "------------------- STDERR ------------------------"
     cat  "${stderr_file}"
     echo "------------------- STDERR ------------------------"

     ## Record cmd_to_run on cache
     echo "${cmd_to_run_hash}:${cmd_to_run_noargs_hash}:$(echo ${cmd_retcode}):${stdout_file}:${stderr_file}:${origcmd_file}:${full_path_cmd_to_run}:" >> ${cache_file}
     echo "Successfully added \""""$(cat ${origcmd_file})"""\" to stub cache"

     ## Creates stub cmd
     {
          echo "#!/usr/bin/env bash"
          echo "## Validate """../${cache_file}""" exists"
          echo ""
          echo "[[ ! -f """${cache_file}""" ]] && { echo """Error: Cache File ${cache_file} does not exist"""; exit 1; }"
          echo ""
          echo "## Get cmd_to_run with args on cache and compares with stub_cmd"
          ##echo "stubcmd_to_run=\"$(grep ${cmd_hash} """${cache_file}""" | sed """s/:/ /g""" | awk '{print $6}' | sed """s/${cache_space}/ /g""")\""
          echo "stubcmd_to_run=\""""$(head -1 """${origcmd_file}"""| sed """s/\"/\\\\\"/g""")"""\""
          echo "stubcmd_prefix=\"\$(echo """\${stubcmd_to_run}""" | awk '{print \$1}')\""
          echo "stubcmd_to_run_args="""\${stubcmd_to_run#\$stubcmd_prefix}""""
          echo "stubcmd_to_run_args="""\${stubcmd_to_run_args#\ }""""
          echo ""
          ###echo "echo \"\${stubcmd_to_run_args}\":\$*:"
          echo "if [ \"\$*\" == \"\${stubcmd_to_run_args}\" ]; then"
          echo "    ## if \\$\\@ match, no run and show cache stderr, stdout and returns cache return code"
          echo ""
          echo "    cat """${stdout_file}""""
          echo "    [[ -s """${stderr_file}""" ]] && { cat """${stderr_file}""" > @2 ; }"
          ###echo "    echo """no run""" "
          echo "    exit """${cmd_retcode}""""
          echo "else"
          echo "    ## if \\$\\@ does not match, run command from original location (cached) with arguments"
          echo "    stubcmd_to_run=""\$(grep \"${cmd_hash}\"  \"${cache_file}\"  | sed \"s/:/ /g\" | awk '{print \$7}')"
          echo "    echo \${stubcmd_to_run} \${*}"
          echo "    eval \${stubcmd_to_run} \${*}"
          ###echo "    echo run"
          echo "fi"
      } > "${binstubs_dir}/${cmd_to_run_noargs_hash}.bash"

      ##cat "${binstubs_dir}/${cmd_hash}.bash"
      chmod 755 "${binstubs_dir}/${cmd_to_run_noargs_hash}.bash"

      ## Link stub cmd on "./"
      cd ${binstubs_dir}
      ln -s "${cmd_to_run_noargs_hash}.bash" "${alias_cmd}"
      cd -
  fi

}


while getopts ":h" arg; do
  case $arg in
    r)
      exp_retcode="${OPTARG}"
      ;;
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
