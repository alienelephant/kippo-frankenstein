kippo-frankenstein
==================

My attempt to merge all kippo forks/features I find useful into one repo.

Forked from: https://github.com/micheloosterhof/kippo

Extra Code merged from (or will be):
* https://github.com/g0tmi1k/kippo-patches
* https://github.com/toringe/kippomutate
* https://github.com/basilfx/kippo-extra
* https://github.com/rep/hpfeeds/tree/master/appsupport/kippo


When this acutally works I'll create a real readme. Until that time, don't use this. Really.

# Notable Changes

1. Removed "logoff" trick, honeypot just exists cleanly on user logout
2. Merged hpfeeds support and added appropriate kippo.cfg entry (https://github.com/rep/hpfeeds/tree/master/appsupport/kippo)
3. Add commands: which, env
4. Add empty output for commands: bash -c, umask, alias
5. Removed 'exxxit' command
6. Added prompt patches from https://github.com/g0tmi1k/kippo-patches/blob/master/shell_prompt.patch
7. Added realistic errors when executables are run (patched dice.py from https://github.com/toringe/kippomutate/blob/master/kippomutate.sh)
8. Added a setup.sh file which mutates the kippo.cfg and some output from commands (modified from https://github.com/toringe/kippomutate/blob/master/kippomutate.sh)
