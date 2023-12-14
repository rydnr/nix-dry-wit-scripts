# release-tag.sh

Performs a new release tag on a given project:
- Checks if the repository has anything to release.
- Checks if are changes besides `flake.nix` and `flake.lock`. In such case, it stops.
- Commits changes in `flake.nix` and `flake.lock` (using the GPG key if provided).
- Pushes the changes.
- Retrieves the latest semantic-version-compatible version of the project.
- Increases the patch version.
- Creates a tag with the new version.
- Pushes the tag.

``` sh
release-tag.sh [-v|--debug] [-vv|--trace] [-q|--quiet] [-h|--help] -R|--releaseName arg [-r|--repository arg] [-t|--githubToken arg] [-g|--gpgKeyId arg] [-c|--commitMessage arg] [-m|--tagMessage arg]
Copyleft 2023-today Automated Computing Machinery S.L.
Distributed under the terms of the GNU General Public License v3

Creates a release tag of a given git repository

Where:
  * -v|--debug: Display debug messages. Optional.
  * -vv|--trace: Display trace messages. Optional.
  * -q|--quiet: Be silent. Optional.
  * -h|--help: Display information about how to use the script. Optional.
  * -R|--releaseName arg: The release name. Mandatory.
  * -r|--repository arg: The cloned repository. Optional.
  * -t|--githubToken arg: The github token. Optional.
  * -g|--gpgKeyId arg: The id of the GPG key. Optional.
  * -c|--commitMessage arg: The commit message. Optional.
  * -m|--tagMessage arg: The tag message. Optional.
```
