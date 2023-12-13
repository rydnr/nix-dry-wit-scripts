#!/usr/bin/env dry-wit
# Copyright 2023-today Automated Computing Machinery S.L.
# Distributed under the terms of the GNU General Public License v3

DW.import file;
DW.import nix-flake;
DW.import git;

# fun: main
# api: public
# txt: Main logic. Gets called by dry-wit.
# txt: Returns 0/TRUE if some inputs get updated; 1/FALSE otherwise, and other values in case of errors.
# use: if main; then echo "Inputs updated"; fi
function main() {
  local _flakeNix="${FLAKE_NIX_FILE}";

  local -i _rescode=${FALSE};

  if isEmpty "${_flakeNix}"; then
    _flakeNix="${PWD}/flake.nix";
    if ! fileExists "${_flakeNix}"; then
      _flakeNix="${PWD}/nix/flake.nix";
    fi
    if ! fileExists "${_flakeNix}"; then
      exitWithErrorCode FLAKE_NIX_FILE_DOES_NOT_EXIST "${PWD}";
    fi
  fi

  local _flakeLock="${FLAKE_LOCK_FILE}";
  if isEmpty "${_flakeLock}"; then
    _flakeLock="$(dirname "${_flakeLock}")/$(basename ${_flakeNix} .nix).lock";
    if ! fileExists "${_flakeLock}"; then
      exitWithErrorCode FLAKE_LOCK_FILE_DOES_NOT_EXIST "${PWD}";
    fi
  fi

  logDebug -n "Updating ${_flakeLock}";
  if updateFlakeLock "${_flakeNix}"; then
    logDebugResult SUCCESS "done";
  else
    logDebugResult FAILURE "failed";
    exitWithErrorCode CANNOT_UPDATE_FLAKE_LOCK "${_flakeLock}";
  fi

  local _inputs;
  logDebug -n "Extracting inputs from ${_flakeNix}";
  if extractInputsFromFlakeLock "${_flakeLock}"; then
    _inputs="${RESULT}";
    logDebugResult SUCCESS "done";
  else
    logDebugResult FAILURE "error";
    exitWithErrorCode CANNOT_EXTRACT_INPUTS_FROM_FLAKE_LOCK "${_flakeLock}";
  fi

  local _origIFS="${IFS}";
  IFS="${DWIFS}";
  for _input in ${_inputs}; do
    IFS=${_origIFS};
    local _name="$(echo "${_input}" | cut -d ':' -f 1)";
    local _owner="$(echo "${_input}" | cut -d ':' -f 2 | cut -d '/' -f 1)";
    local _repo="$(echo "${_input}" | cut -d ':' -f 2 | cut -d '/' -f 2)";
    local _tag="$(echo "${_input}" | cut -d ':' -f 2 | cut -d '/' -f 3)";
    logInfo -n "Retrieving latest remote tag of github:${_owner}/${_repo}";
    if retrieveLatestRemoteTagInGithub "${_owner}" "${_repo}" "${GITHUB_TOKEN}"; then
      local _latest_tag="${RESULT}";
      logInfoResult SUCCESS "${_latest_tag}";
      if ! areEqual "${_tag}" "${_latest_tag}"; then
        _rescode=${TRUE};
        logInfo -n "Updating ${_owner}/${_repo} from ${_tag} to ${_latest_tag} in ${_flakeNix}";
        if updateInputsInFlakeNix "github:${_owner}/${_repo}/${_tag}" "github:${_owner}/${_repo}/${_latest_tag}" "${_flakeNix}"; then
          logInfoResult SUCCESS "done";
          logInfo -n "Updating $(dirname ${_flakeNix})/flake.lock";
          if updateFlakeLock "${_flakeNix}"; then
            logInfoResult SUCCESS "done";
          else
            local _error="${ERROR}";
            logInfoResult FAILURE "failed";
            if isNotEmpty "${_error}"; then
              logDebug "${_error}";
            fi
            exitWithErrorCode CANNOT_UPDATE_FLAKE_LOCK_IN_FLAKE "${_input}";
          fi
        else
          local _error="${ERROR}";
          logInfoResult FAILURE "failed";
          if isNotEmpty "${_error}"; then
            logDebug "${_error}";
          fi
          exitWithErrorCode CANNOT_UPDATE_FLAKE_INPUT_IN_FLAKE "${_input}";
        fi
      fi
    else
      local _error="${ERROR}";
      logInfoResult NEUTRAL "skipped";
      if isNotEmpty "${_error}"; then
        logDebug "${_error}";
      fi
    fi
  done
  IFS=${_origIFS};

  return ${_rescode};
}

## Script metadata and CLI settings.
setScriptDescription "Updates the flake inputs to their latest versions";
setScriptLicenseSummary "Distributed under the terms of the GNU General Public License v3";
setScriptCopyright "Copyleft 2023-today Automated Computing Machinery S.L.";

addCommandLineFlag "flakeNix" "f" "The flake.nix file" OPTIONAL EXPECTS_ARGUMENT;
addCommandLineFlag "flakeLock" "l" "The flake.lock file" OPTIONAL EXPECTS_ARGUMENT;
addCommandLineFlag "githubToken" "t" "The github token" OPTIONAL EXPECTS_ARGUMENT;

checkReq jq;
checkReq sed;
checkReq grep;

addError FLAKE_NIX_FILE_DOES_NOT_EXIST "flake.nix not specified and not found in";
addError FLAKE_LOCK_FILE_DOES_NOT_EXIST "flake.nix not specified and not found in";
addError CANNOT_RETRIEVE_LATEST_VERSION_OF_REPO "Cannot retrieve the latest version of repo";
addError CANNOT_EXTRACT_INPUTS_FROM_FLAKE_LOCK "Cannot extract the inputs from given flake.lock file";
addError CANNOT_EXTRACT_ORG_FROM_FLAKE_INPUT "Cannot extract the 'org' value from";
addError CANNOT_EXTRACT_REPO_FROM_FLAKE_INPUT "Cannot extract the 'repo' value from";
addError CANNOT_UPDATE_FLAKE_INPUT_IN_FLAKE "Cannot update the version of the input";
addError CANNOT_UPDATE_FLAKE_LOCK "Cannot update";
# vim: syntax=sh ts=2 sw=2 sts=4 sr noet
