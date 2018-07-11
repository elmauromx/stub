# Scripts stub.bash and unstub.bash
## Description
The purpose of the scripts in this project is to help test command line process-programs stubbing or caching some processes in order not to run them each time they are invoked.

This suite includes following scripts:
### Script: stub.bash
In a nushell this script do the following:
1. Validates the existance of .binstub and .stubfiles directories
1. Validates that .binstub is the first path in $PATH variable. If not, some lines are added to $HOME/.bash_profile in order to prepend .binstub dir in the path
1. Get a hash for command and arguments
1. Run command with arguments and record hash, return code, stdout, stderr_file and full path for comand invoked
1. Link prepend command to .stub_cmd_launcher.bash script

### Script: .stub_cmd_launcher.bash
This command is invoked through a link in .binstub directory and perform following steps:
1. Get a hash for command an arguments
1. Validate that command + arguments exist in cache.
1. In the case command + arguments are cached, shows stdout, stderr and returns registered return code.
1. In the case command + arguments are not cached, command is invoked on its original path

### Script: unstub.bash
In a nushell this script do the following:
1. Validates the existance of command + arguments in cache.
1. In the cases combination exists, remove entries from cache files and other files
## usage
### stub.bash
```bash
stub.bash command arg1 arg2 \"arg3 arg4\" arg5 ... argn
```
### unstub.bash
```bash
stub.bash command arg1 arg2 \"arg3 arg4\" arg5 ... argn
```
## Examples
