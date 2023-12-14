# update-latest-inputs-nix-flake.sh

Updates inputs to their latest tag in a Nix flake.

``` sh
update-latest-inputs-nix-flake.sh [-v|--debug] [-vv|--trace] [-q|--quiet] [-h|--help] [-f|--flakeNix arg] [-l|--flakeLock arg] [-t|--githubToken arg]
Copyleft 2023-today Automated Computing Machinery S.L.
Distributed under the terms of the GNU General Public License v3

Updates the flake inputs to their latest versions

Where:
  * -v|--debug: Display debug messages. Optional.
  * -vv|--trace: Display trace messages. Optional.
  * -q|--quiet: Be silent. Optional.
  * -h|--help: Display information about how to use the script. Optional.
  * -f|--flakeNix arg: The flake.nix file. Optional.
  * -l|--flakeLock arg: The flake.nix file. Optional.
  * -t|--githubToken arg: The github token. Optional.
```
