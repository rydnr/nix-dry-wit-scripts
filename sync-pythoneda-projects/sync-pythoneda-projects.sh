#!/usr/bin/env dry-wit
# Copyright 2023-today Automated Computing Machinery S.L.
# Distributed under the terms of the GNU General Public License v3

DW.import file;
DW.import nix-flake;
DW.import git;

# fun: main
# api: public
# txt: Main logic. Gets called by dry-wit.
# txt: Returns 0/TRUE always, but may exit due to errors.
# use: main
function main() {

  local _projects=( \
    "pythoneda-shared-pythoneda/banner" \
    "pythoneda-shared-pythoneda/domain" \
    "pythoneda-shared-pythoneda/infrastructure" \
    "pythoneda-shared-artifact/events" \
    "pythoneda-shared-artifact/artifact-events" \
    "pythoneda-shared-git/shared" \
    "pythoneda-shared-nix-flake/shared" \
    "pythoneda-shared-artifact/shared" \
    "pythoneda-shared-pythoneda/application" \
    "pythoneda-shared-artifact/artifact-shared" \
    "pythoneda-shared-artifact/events-infrastructure" \
    "pythoneda-shared-artifact/artifact-events-infrastructure" \
    "pythoneda-shared-artifact/artifact-infrastructure" \
    "pythoneda-shared-artifact/infrastructure" \
    "pythoneda-shared-artifact/application" \
    "pythoneda-shared-code-requests/shared" \
    "pythoneda-shared-code-requests/events" \
    "pythoneda-shared-code-requests/events-infrastructure" \
    "pythoneda-shared-code-requests/jupyterlab" \
    "pythoneda-shared-artifact/code-events" \
    "pythoneda-shared-artifact/code-events-infrastructure" \
    "pythoneda-realm-rydnr/events" \
    "pythoneda-realm-rydnr/events-infrastructure" \
    "pythoneda-realm-rydnr/realm" \
    "pythoneda-realm-rydnr/infrastructure" \
    "pythoneda-realm-rydnr/application" \
    "pythoneda-realm-unveilingpartner/realm" \
    "pythoneda-realm-unveilingpartner/infrastructure" \
    "pythoneda-realm-unveilingpartner/application" \
    "pythoneda-sandbox/python-dep" \
    "pythoneda-sandbox/python" \
    "pythoneda-sandbox-artifact/python-dep" \
    "pythoneda-sandbox-artifact/python" \
    "pythoneda-sandbox-artifact/python-artifact" \
    "pythoneda-sandbox-artifact/python-infrastructure" \
    "pythoneda-sandbox-artifact/python-application" \
    "pythoneda-artifact/git" \
    "pythoneda-artifact/git-infrastructure" \
    "pythoneda-artifact/git-application" \
    "pythoneda-artifact/nix-flake" \
    "pythoneda-artifact/nix-flake-infrastructure" \
    "pythoneda-artifact/nix-flake-application" \
    "pythoneda-artifact/code-request-infrastructure" \
    "pythoneda-artifact/code-request-application" \
    "pythoneda-shared-pythoneda-artifact/domain" \
    "pythoneda-shared-pythoneda-artifact/domain-infrastructure" \
    "pythoneda-shared-pythoneda-artifact/domain-application" \
    );

  resolveVerbosity;
  local _commonArgs=(${RESULT});
  if ! isEmpty "${GITHUB_TOKEN}"; then
    _commonArgs+=("-t" "${GITHUB_TOKEN}");
  fi
  local _releaseTagArgs=("${_commonArgs[@]}" "-R" "${RELEASE_NAME}");
  if ! isEmpty "${COMMIT_MESSAGE}"; then
    _releaseTagArgs+=("-c" "${COMMIT_MESSAGE}");
  fi
  if ! isEmpty "${TAG_MESSAGE}"; then
    _releaseTagArgs+=("-m" "${TAG_MESSAGE}");
  fi
  if ! isEmpty "${GPG_KEY_ID}"; then
    _releaseTagArgs+=("-g" "${GPG_KEY_ID}");
  fi
  local _updatedProjects=();
  local _upToDateProjects=();
  local _failedProjects=();
  local _project;
  local _def_owner;
  local _repo;
  local -i _rescode;
  local _output;
  local _origIFS="${IFS}";
  IFS="${DWIFS}";
  for _project in "${_projects[@]}"; do
    IFS="${_origIFS}";
    if extract_owner "${_project}"; then
      _def_owner="${RESULT}-def";
    else
      exitWithErrorCode CANNOT_EXTRACT_THE_OWNER_OF_PROJECT "${_project}";
    fi
    if extract_repo "${_project}"; then
      _repo="${RESULT}";
    else
      exitWithErrorCode CANNOT_EXTRACT_THE_REPOSITORY_NAME_OF_PROJECT "${_project}";
    fi
    pushd ${ROOT_FOLDER}/${_def_owner}/${_repo} >/dev/null 2>&1 || exitWithErrorCode PROJECT_FOLDER_DOES_NOT_EXIST "${ROOT_FOLDER}/${_def_owner}/${_repo}"
    logInfo -n "Checking if ${_def_owner}/${_repo} needs to be updated";
    _output="$("${UPDATE_LATEST_INPUTS_NIX_FLAKE}" "${_commonArgs[@]}" -f flake.nix -l flake.lock 2>&1)";
    _rescode=$?;
    echo
    echo "${_output}"
    if isTrue ${_rescode}; then
      logInfoResult SUCCESS "true";
      _output="$("${RELEASE_TAG}" "${_releaseTagArgs[@]}" -r "${ROOT_FOLDER}/${_def_owner}/${_repo}" 2>&1)";
      _rescode=$?;
      if isTrue ${_rescode}; then
        _updatedProjects+=("$(command echo "${_output}" | command tail -n 1)");
      else
        if ! isEmpty "${_output}"; then
          logDebug "${_output}";
        fi
        _failedProjects+=("${_def_owner}/${_repo}");
      fi
    else
      logInfoResult SUCCESS "false";
      _upToDateProjects+=("${_def_owner}/${_repo}");
    fi
    popd 2>&1 > /dev/null || exitWithErrorCode PROJECT_FOLDER_DOES_NOT_EXIST "${_project}"
    IFS="${_origIFS}";
  done
  IFS="${_origIFS}";

  if isNotEmpty "${_failedProjects[@]}"; then
    logInfo -n "Number of projects that couldn't be updated";
    logInfoResult SUCCESS "${#_failedProjects[@]}";
    IFS="${DWIFS}";
    for _project in "${_failedProjects[@]}"; do
      IFS="${_origIFS}";
      logInfo "${_project}";
    done
    IFS="${_origIFS}";
  fi

  if isNotEmpty "${_upToDateProjects[@]}"; then
    logInfo -n "Number of projects already up to date";
    logInfoResult SUCCESS "${#_upToDateProjects[@]}";
    IFS="${DWIFS}";
    for _project in "${_upToDateProjects[@]}"; do
      IFS="${_origIFS}";
      logInfo "${_project}";
    done
    IFS="${_origIFS}";
  fi

  if isNotEmpty "${_updatedProjects[@]}"; then
    logInfo -n "Number of projects updated";
    logInfoResult SUCCESS "${#_updatedProjects[@]}";
    IFS="${DWIFS}";
    for _project in "${_updatedProjects[@]}"; do
      IFS="${_origIFS}";
      logInfo "${_project}";
    done
    IFS=','
    echo "${_updatedProjects[*]}"
    echo "${_updatedProjects[*]}" | jq '.'
    IFS="${_origIFS}";
  fi
}

# fun: extract_owner project
# api: public
# txt: Extracts the owner from given project name.
# opt: project: The project name.
# txt: Returns 0/TRUE if the owner could be extracted; 1/FALSE otherwise.
# txt: If the function returns 0/TRUE, the variable RESULT will contain the owner.
# use: if extract_owner "pythoneda-shared-pythoneda/domain"; then echo "Owner: ${RESULT}"; fi
function extract_owner() {
  local _project="${1}";
  checkNotEmpty project "${_project}" 1;

  local -i _rescode=${FALSE};
  local _result;

  _result="$(echo "${_project}" | cut -d '/' -f 1 2>/dev/null)";
  _rescode=$?;

  if isEmpty "${_result}"; then
     _rescode=${FALSE};
  fi
  if isTrue ${_rescode}; then
    export RESULT="${_result}";
  fi

  return ${_rescode};
}

# fun: extract_repo project
# api: public
# txt: Extracts the repository from given project name.
# opt: project: The project name.
# txt: Returns 0/TRUE if the repository could be extracted; 1/FALSE otherwise.
# txt: If the function returns 0/TRUE, the variable RESULT will contain the repository name.
# use: if extract_repo "pythoneda-shared-pythoneda/domain"; then echo "Repo: ${RESULT}"; fi
function extract_repo() {
  local _project="${1}";
  checkNotEmpty project "${_project}" 1;

  local -i _rescode=${FALSE};
  local _result;

  _result="$(command echo "${_project}" | command cut -d '/' -f 2 2>/dev/null)";
  _rescode=$?;
  if isEmpty "${_result}"; then
     _rescode=${FALSE};
  fi
  if isTrue ${_rescode}; then
    export RESULT="${_result}";
  fi

  return ${_rescode};
}

## Script metadata and CLI settings.
setScriptDescription "Synchronizes PythonEDA projects";
setScriptLicenseSummary "Distributed under the terms of the GNU General Public License v3";
setScriptCopyright "Copyleft 2023-today Automated Computing Machinery S.L.";

addCommandLineFlag "rootFolder" "r" "The root folder of PythonEDA definition projects" MANDATORY EXPECTS_ARGUMENT;
addCommandLineFlag "githubToken" "t" "The github token" OPTIONAL EXPECTS_ARGUMENT;
addCommandLineFlag "releaseName" "R" "The release name" MANDATORY EXPECTS_ARGUMENT;
addCommandLineFlag "gpgKeyId" "g" "The id of the GPG key" OPTIONAL EXPECTS_ARGUMENT;

checkReq jq;
checkReq sed;
checkReq grep;

addError ROOT_FOLDER_DOES_NOT_EXIST "Given root folder for definition projects does not exist:";
addError PROJECT_FOLDER_DOES_NOT_EXIST "Project folder does not exist:"
addError CANNOT_EXTRACT_THE_OWNER_OF_PROJECT "Cannot extract the owner of project:";
addError CANNOT_EXTRACT_THE_REPOSITORY_NAME_OF_PROJECT "Cannot extract the repository name of project:";
addError CANNOT_UPDATE_LATEST_INPUTS "Cannot update inputs to its latest versions in";
addError CANNOT_RELEASE_TAG "Cannot create a new release tag in";

## deps
export UPDATE_LATEST_INPUTS_NIX_FLAKE="__UPDATE_LATEST_INPUTS_NIX_FLAKE__";
if areEqual "${UPDATE_LATEST_INPUTS_NIX_FLAKE}" "__UPDATE_LATEST_INPUTS_NIX_FLAKE__"; then
  export UPDATE_LATEST_INPUTS_NIX_FLAKE="update-latest-inputs-nix-flake.sh";
fi
export RELEASE_TAG="__RELEASE_TAG__";
if areEqual "${RELEASE_TAG}" "__RELEASE_TAG__"; then
  export RELEASE_TAG="release-tag.sh";
fi

function dw_check_rootFolder_cli_flag() {
  if ! fileExists "${ROOT_FOLDER}"; then
    exitWithErrorCode ROOT_FOLDER_DOES_NOT_EXIST "${ROOT_FOLDER}"
  fi
}
# vim: syntax=sh ts=2 sw=2 sts=4 sr noet
