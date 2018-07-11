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
Note. Keep in mind that if you requiere to pass double quoting mark " on arguments, it must be escaped
### unstub.bash
```bash
stub.bash command arg1 arg2 \"arg3 arg4\" arg5 ... argn
```
Note. Keep in mind that if you requiere to pass double quoting mark " on arguments, it must be escaped
## Examples

### Stub command 'date +%s'
```bash
stub.bash date +%s
```
you should see output similar to:
```bash
Command:       "date +%s"
Return Code:   "0"
------------------- STDOUT ------------------------
1531273997
------------------- STDOUT ------------------------
------------------- STDERR ------------------------
------------------- STDERR ------------------------
Successfully added "date +%s" to stub cache
```
Now, you are able to run command 'date +%s' from command line, and the output will be always the cached one: 1531273997
```bash
date +%s
1531273997
```

```bash
date +%s
1531273997
```
But if you run date command with different arguments, it should be run from its original location (and output would vary depending on arguments). Examples:
```bash
date
Tue Jul 10 20:57:37 CDT 2018
```
```bash
date +%Y%m%d-%H%M%S
20180710-205922
```
```bash
date +%Y%m%d-%H%M%S
20180710-205945
```
### Unstub command 'date +%s'
```bash
unstub.bash date +%s
```
you should see output similar to:
```bash
------------------Stubbed Command------------------
Command:       "date +%s"
Return Code:   "0"
------------------- STDOUT ------------------------
------------------- STDOUT ------------------------
------------------- STDERR ------------------------
------------------- STDERR ------------------------

Removing origcmd file:         ".stubfiles/.stub.origcmd.411874bf167dc5c4a77c58d610f8d29054996c39.tmp"
Removing stdout file:          ".stubfiles/.stub.stdout.411874bf167dc5c4a77c58d610f8d29054996c39.tmp"
Removing stderr file:          ".stubfiles/.stub.stderr.411874bf167dc5c4a77c58d610f8d29054996c39.tmp"
---------------------------------------------------
Successfully removed "date +%s" from stub cache
```
### Stub command 'date \"+%Y%m%d %H%M%S\"'
Whenever you need to add double quote mark, you need to escape it. Example:
```bash
stub.bash date \"+%Y%m%d %H%M%S\"
```
you should see output similar to:
```bash
Command:       "date "+%Y%m%d %H%M%S""
Return Code:   "0"
------------------- STDOUT ------------------------
20180710 211811
------------------- STDOUT ------------------------
------------------- STDERR ------------------------
------------------- STDERR ------------------------
```
Now, you are able to run command 'date \"+%Y%m%d %H%M%S\"' from command line and the output will be always the cached one: '20180710 211811'.
Remember to escape double quoute marks or cached command will never match.
```bash
date \"+%Y%m%d %H%M%S\"
20180710 211811
```
### Untub command 'date \"+%Y%m%d %H%M%S\"'
Whenever you need to add double quote mark, you need to escape it. Example:
```bash
unstub.bash date \"+%Y%m%d %H%M%S\"
```
you should see output similar to:
```bash
------------------Stubbed Command------------------
Command:       "date "+%Y%m%d %H%M%S""
Return Code:   "0"
------------------- STDOUT ------------------------
------------------- STDOUT ------------------------
------------------- STDERR ------------------------
------------------- STDERR ------------------------

Removing origcmd file:         ".stubfiles/.stub.origcmd.1217fc928199887a48364ef287b16d5e2336e08f.tmp"
Removing stdout file:          ".stubfiles/.stub.stdout.1217fc928199887a48364ef287b16d5e2336e08f.tmp"
Removing stderr file:          ".stubfiles/.stub.stderr.1217fc928199887a48364ef287b16d5e2336e08f.tmp"
---------------------------------------------------
Successfully removed "date "+%Y%m%d %H%M%S"" from stub cache
```
