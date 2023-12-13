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
  local _org;

  local _flakeFile="${FLAKE_FILE}";
  if isEmpty "${_flakeFile}"; then
    _flakeFile="${PWD}/flake.nix";
    if ! fileExists "${_flakeFile}"; then
      _flakeFile="${PWD}/nix/flake.nix";
    fi
    if ! fileExists "${_flakeFile}"; then
      exitWithErrorCode FLAKE_FILE_DOES_NOT_EXIST "${PWD}";
    fi
  fi

  logDebug -n "Extracting org from ${_flakeFile}";
  if extractOrgFromFlakeNix "${_flakeFile}"; then
    _org="${RESULT}";
    logDebugResult SUCCESS "${_org}";
  else
    logDebugResult FAILURE "error";
    exitWithErrorCode CANNOT_EXTRACT_ORG_FROM_FLAKE "${_flakeFile}";
  fi

  local _repo;
  logDebug -n "Extracting repo from ${_flakeFile}";
  if extractRepoFromFlakeNix "${_flakeFile}"; then
    _repo="${RESULT}";
    logDebugResult SUCCESS "${_repo}";
  else
    logDebugResult FAILURE "error";
    exitWithErrorCode CANNOT_EXTRACT_REPO_FROM_FLAKE "${_flakeFile}";
  fi

  local _projectVersion="${PROJECT_VERSION}";
  if isEmpty "${_projectVersion}"; then
    logDebug -n "Retrieving latest tag of ${_org}/${_repo}";
    if retrieveLatestRemoteTagInGithub "${_org}" "${_repo}"; then
      _projectVersion="${RESULT}";
      logDebugResult SUCCESS "${_projectVersion}";
    else
      logDebugResult FAILURE "error";
      exitWithErrorCode CANNOT_RETRIEVE_LATEST_VERSION_OF_REPO "${_repo}";
    fi
  fi

  local -i _updateSha256=${FALSE};

  if fileContains "${_flakeFile}" "sha256 ="; then
    _updateSha256=${TRUE};
  fi

  logDebug -n "Updating version in ${_flakeFile} to ${_projectVersion}";
  if updateVersionInFlakeNix "${_flakeFile}" "${_projectVersion}"; then
    logDebugResult SUCCESS "done";
  else
    logDebugResult FAILURE "error";
    exitWithErrorCode CANNOT_UPDATE_VERSION_IN_FLAKE "${_flakeFile} ${_projectVersion}";
  fi

  if isTrue ${_updateSha256}; then
    local _sha256;
    local _url="https://github.com/${_org}/${_repo}";
    logDebug -n "Fetching sha256 of ${_url}, rev ${_projectVersion}"
    if fetchSha256FromUrl "${_url}" "${_projectVersion}"; then
      _sha256="${RESULT}";
      logDebugResult SUCCESS "${_sha256}";
    else
      logDebugResult FAILURE "error";
      exitWithErrorCode CANNOT_FETCH_SHA256_FROM_URL "${_url} ${_projectVersion}";
    fi

    logDebug -n "Updating sha256 in ${_flakeFile}";
    if updateSha256InFlakeNix "${_flakeFile}" "${_sha256}"; then
      logDebugResult SUCCESS "done";
    else
      logDebugResult FAILURE "error";
      exitWithErrorCode CANNOT_UPDATE_SHA256_IN_FLAKE "${_flakeFile} ${_sha256}";
    fi
  fi

  if isTrue ${_updateSha256}; then
    logInfo "Updated version and sha256 in ${_flakeFile}"
  else
    logInfo "Updated version in ${_flakeFile}"
  fi
}

## Script metadata and CLI settings.
setScriptDescription "Updates the version and sha256 hash of a PythonEDA-specific Nix flake";
setScriptLicenseSummary "Distributed under the terms of the GNU General Public License v3";
setScriptCopyright "Copyleft 2023-today Automated Computing Machinery S.L.";

addCommandLineFlag "version" "V" "The version" OPTIONAL EXPECTS_ARGUMENT;
addCommandLineFlag "flake" "f" "The Nix flake" OPTIONAL EXPECTS_ARGUMENT;

checkReq nix-prefetch-git;
checkReq jq;
checkReq sed;
checkReq grep;

addError FLAKE_FILE_DOES_NOT_EXIST "Flake file not specified and not found in ";
addError CANNOT_RETRIEVE_LATEST_VERSION_OF_REPO "Cannot retrieve the latest version of repo ";
addError CANNOT_EXTRACT_ORG_FROM_FLAKE "Cannot extract the 'org' value from ";
addError CANNOT_EXTRACT_REPO_FROM_FLAKE "Cannot extract the 'repo' value from ";
addError CANNOT_FETCH_SHA256_FROM_URL "Cannot fetch the sha256 hash from ";
addError CANNOT_UPDATE_VERSION_IN_FLAKE "Cannot update the 'version' value in ";
addError CANNOT_UPDATE_SHA256_IN_FLAKE "Cannot update the 'sha256' value in ";

function dw_parse_version_cli_flag() {
  export PROJECT_VERSION="${1}";
}

function dw_parse_flake_cli_flag() {
  export FLAKE_FILE="${1}";
}
# vim: syntax=sh ts=2 sw=2 sts=4 sr noet
