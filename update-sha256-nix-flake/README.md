# update-sha256-nix-flake.sh

Updates the sha256 checksum in a flake.nix file.

``` sh
update-sha256-nix-flake.sh [-v|--debug] [-vv|--trace] [-q|--quiet] [-h|--help] [-V|--projectVersion arg] [-f|--flakeFile arg]
Copyleft 2023-today Automated Computing Machinery S.L.
Distributed under the terms of the GNU General Public License v3

Updates the version and sha256 hash of a PythonEDA-specific Nix flake

Where:
  * -v|--debug: Display debug messages. Optional.
  * -vv|--trace: Display trace messages. Optional.
  * -q|--quiet: Be silent. Optional.
  * -h|--help: Display information about how to use the script. Optional.
  * -V|--projectVersion arg: The version. Optional.
  * -f|--flakeFile arg: The Nix flake. Optional.
```
