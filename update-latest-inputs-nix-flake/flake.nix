# update-latest-inputs-nix-flake/flake.nix
#
# This file packages update-latest-inputs-nix-flake script as a Nix flake.
#
# Copyright (C) 2008-today rydnr's nix-dry-wit-scripts
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
{
  description =
    "Nix flake for rydnr/nix-dry-wit-scripts/update-latest-inputs-nix-flake";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/24.05";
    dry-wit = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:rydnr/dry-wit/3.0.20?dir=nix";
    };
    pythoneda-shared-pythonlang-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.61";
    };
  };
  outputs = inputs:
    with inputs;
    let
      defaultSystems = flake-utils.lib.defaultSystems;
      supportedSystems = if builtins.elem "armv6l-linux" defaultSystems then
        defaultSystems
      else
        defaultSystems ++ [ "armv6l-linux" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        org = "rydnr";
        repo = "nix-dry-wit-scripts";
        pname = "${org}-${repo}";
        version = "0.0.28";
        pkgs = import nixos { inherit system; };
        description =
          "dry-wit script to update the versions of the inputs of a given flake.nix file, to their latest tags";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        update-latest-inputs-nix-flake-for = { dry-wit }:
          pkgs.stdenv.mkDerivation rec {
            inherit pname version;
            src = ../.;
            propagatedBuildInputs = [ dry-wit ];
            phases = [ "unpackPhase" "installPhase" ];

            installPhase = ''
              mkdir -p $out/bin
              cp update-latest-inputs-nix-flake/update-latest-inputs-nix-flake.sh $out/bin
              chmod +x $out/bin/update-latest-inputs-nix-flake.sh
              cp update-latest-inputs-nix-flake/README.md LICENSE $out/
              substituteInPlace $out/bin/update-latest-inputs-nix-flake.sh \
                --replace "#!/usr/bin/env dry-wit" "#!/usr/bin/env ${dry-wit}/dry-wit"
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = update-latest-inputs-nix-flake-default;
          update-latest-inputs-nix-flake-default =
            update-latest-inputs-nix-flake-bash5;
          update-latest-inputs-nix-flake-bash5 = shared.app-for {
            package = packages.update-latest-inputs-nix-flake-bash5;
            entrypoint = "update-latest-inputs-nix-flake";
          };
          update-latest-inputs-nix-flake-zsh = shared.app-for {
            package = packages.update-latest-inputs-nix-flake-zsh;
            entrypoint = "update-latest-inputs-nix-flake";
          };
          update-latest-inputs-nix-flake-fish = shared.app-for {
            package = packages.update-latest-inputs-nix-flake-fish;
            entrypoint = "update-latest-inputs-nix-flake";
          };
        };
        defaultPackage = packages.default;
        packages = rec {
          default = update-latest-inputs-nix-flake-default;
          update-latest-inputs-nix-flake-default =
            update-latest-inputs-nix-flake-bash5;
          update-latest-inputs-nix-flake-bash5 =
            update-latest-inputs-nix-flake-for {
              dry-wit = dry-wit.packages.${system}.dry-wit-bash5;
            };
          update-latest-inputs-nix-flake-zsh =
            update-latest-inputs-nix-flake-for {
              dry-wit = dry-wit.packages.${system}.dry-wit-zsh;
            };
          update-latest-inputs-nix-flake-fish =
            update-latest-inputs-nix-flake-for {
              dry-wit = dry-wit.packages.${system}.dry-wit-fish;
            };
        };
      });
}
