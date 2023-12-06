# Nix dry-wit scripts

Miscellaneus dry-wit (Bash) scripts focused on [Nix](https://nixos.org "Nix").

## update-sha256-nix-flake.sh

Updates the `sha256` value of the package built by a Nix flake.

### Usage

``` sh
update-sha256-nix-flake.sh [-v|--debug] [-vv|--trace] [-q|--quiet] [-h|--help] [-V|--version arg] [-f|--flake arg]
Copyleft 2023-today Automated Computing Machinery S.L.
Distributed under the terms of the GNU General Public License v3

Updates the version and sha256 hash of a PythonEDA-specific Nix flake

Where:
  * -v|--debug: Display debug messages. Optional.
  * -vv|--trace: Display trace messages. Optional.
  * -q|--quiet: Be silent. Optional.
  * -h|--help: Display information about how to use the script. Optional.
  * -V|--version arg: The version. Optional.
  * -f|--flake arg: The Nix flake. Optional.
```

## update-latest-inputs-nix-flake.sh

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
