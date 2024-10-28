# update-sha256-nix-flake/flake.nix
#
# This file packages update-sha256-nix-flake script as a Nix flake.
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
  description = "dry-wit script to update the sha256 values of flake.nix files";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/24.05";
    dry-wit = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:rydnr/dry-wit/3.0.18?dir=nix";
    };
    pythoneda-shared-pythoneda-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythoneda-def/banner/0.0.48";
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
        version = "0.0.16";
        pkgs = import nixos { inherit system; };
        description =
          "dry-wit script to update the sha256 values of flake.nix files";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        shared = import "${pythoneda-shared-pythoneda-banner}/nix/shared.nix";
        update-sha256-nix-flake-for = { dry-wit }:
          pkgs.stdenv.mkDerivation rec {
            inherit pname version;
            src = ../.;
            propagatedBuildInputs = [ dry-wit ];
            phases = [ "unpackPhase" "installPhase" ];

            installPhase = ''
              mkdir -p $out/bin
              cp -r update-sha256-nix-flake/update-sha256-nix-flake.sh $out/bin
              chmod +x $out/bin/update-sha256-nix-flake.sh
              cp update-sha256-nix-flake/README.md LICENSE $out/
              substituteInPlace $out/bin/update-sha256-nix-flake.sh \
                --replace "#!/usr/bin/env dry-wit" "#!/usr/bin/env ${dry-wit}/dry-wit"
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = update-sha256-nix-flake-default;
          update-sha256-nix-flake-default = update-sha256-nix-flake-bash5;
          update-sha256-nix-flake-bash5 = shared.app-for {
            package = packages.update-sha256-nix-flake-bash5;
            entrypoint = "update-sha256-nix-flake";
          };
          update-sha256-nix-flake-zsh = shared.app-for {
            package = packages.update-sha256-nix-flake-zsh;
            entrypoint = "update-sha256-nix-flake";
          };
          update-sha256-nix-flake-fish = shared.app-for {
            package = packages.update-sha256-nix-flake-fish;
            entrypoint = "update-sha256-nix-flake";
          };
        };
        defaultPackage = packages.default;
        packages = rec {
          default = update-sha256-nix-flake-default;
          update-sha256-nix-flake-default = update-sha256-nix-flake-bash5;
          update-sha256-nix-flake-bash5 = update-sha256-nix-flake-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-bash5;
          };
          update-sha256-nix-flake-zsh = update-sha256-nix-flake-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-zsh;
          };
          update-sha256-nix-flake-fish = update-sha256-nix-flake-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-fish;
          };
        };
      });
}
