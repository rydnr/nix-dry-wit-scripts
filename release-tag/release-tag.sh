#!/usr/bin/env dry-wit
# Copyright 2023-today Automated Computing Machinery S.L.
# Distributed under the terms of the GNU General Public License v3

DW.import file
DW.import git
DW.import url
DW.import github
DW.import gpg
DW.import nix-flake

# fun: main
# api: public
# txt: Main logic. Gets called by dry-wit.
# txt: Returns 0/TRUE always, but may exit due to errors.
# use: main
function main() {
  local _gitRepo="${REPOSITORY}"
  if isEmpty "${_gitRepo}"; then
    _gitRepo="${PWD}"
    if ! folderExists "${_gitRepo}"; then
      exitWithErrorCode REPOSITORY_DOES_NOT_EXIST "${_gitRepo}"
    fi
  fi

  local _url
  if retrieveRepositoryUrl "${_gitRepo}"; then
    _url="${RESULT}"
  else
    exitWithErrorCode FOLDER_IS_NOT_A_GIT_REPOSITORY
  fi
  local _owner="unknown"
  if extractOwnerFromGithubUrl "${_url}"; then
    _owner="${RESULT}"
  fi
  local _repoName="unknown"
  if extractRepoFromGithubUrl "${_url}"; then
    _repoName="${RESULT}"
  fi
  local -i _release=${FALSE}
  local -i _gitAdd=${FALSE}

  logDebug -n "Checking if ${_owner}/${_repoName} contains anything to release"
  if isGitRepoDirty "${_gitRepo}"; then
    logDebugResult SUCCESS "true"
    logDebug -n "Checking if ${_owner}/${_repoName} contains modifications in flake.nix and flake.lock"
    if gitRepoContainsModificationsIn "${_gitRepo}" "flake.nix" "flake.lock"; then
      logDebugResult SUCCESS "true"
      _gitAdd=${TRUE}
    else
      logDebugResult NEUTRAL "false"
      if isTrue "${FORCE}"; then
        _release=${TRUE}
      else
        logInfo "Skipping ${_owner}/${_repoName} since it has no changes in flake files"
      fi
    fi
    if isFalse "${_gitAdd}"; then
      logDebug -n "Checking if ${_owner}/${_repoName} contains modifications besides flake.nix and flake.lock"
      if gitRepoContainsModificationsBesides "${_gitRepo}" "flake.nix" "flake.lock"; then
        logDebugResult NEUTRAL "dirty"
        if isTrue "${FORCE}"; then
          _release=${TRUE}
        else
          logInfo "Skipping ${_owner}/${_repoName} since it has uncommitted changes"
        fi
      fi
    fi
    if isTrue ${_gitAdd}; then
      logInfo -n "Committing flake.nix and flake.lock in ${_owner}/${_repoName}"
      if ! gitAdd "${_gitRepo}" "flake.nix"; then
        local _error="${ERROR}"
        logInfoResult FAILURE "failed"
        if ! isEmpty "${_error}"; then
          logDebug "${_error}"
        fi
        exitWithErrorCode CANNOT_ADD_FLAKE_NIX "${_gitRepo}"
      fi
      if ! gitAdd "${_gitRepo}" "flake.lock"; then
        local _error="${ERROR}"
        logInfoResult FAILURE "failed"
        if ! isEmpty "${_error}"; then
          logDebug "${_error}"
        fi
        exitWithErrorCode CANNOT_ADD_FLAKE_NIX "${_gitRepo}"
      fi
      if ! gitCommit "${_gitRepo}" "${COMMIT_MESSAGE}" "${GPG_KEY_ID}"; then
        local _error="${ERROR}"
        logInfoResult FAILURE "failed"
        if ! isEmpty "${_error}"; then
          logDebug "${_error}"
        fi
        exitWithErrorCode GIT_COMMIT_FAILED "${_gitRepo}"
      fi
      logInfoResult SUCCESS "done"
      _release=${TRUE}
    fi
    if isTrue "${_release}"; then
      release "${_gitRepo}"
      local _newVersion="${RESULT}"
      logDebug -n "Pushing the tags in ${_gitRepo}"
      if gitPushTags "${_gitRepo}"; then
        logDebugResult SUCCESS "done"
      else
        local _error="${ERROR}"
        logInfoResult FAILURE "failed"
        if ! isEmpty "${_error}"; then
          logDebug "${_error}"
        fi
        exitWithErrorCode GIT_PUSH_TAGS_FAILED "${_gitRepo}"
      fi
      command echo "${_newVersion}"
    fi
  else
    logDebugResult SUCCESS "clean"
    logInfo "Skipping ${_owner}/${_repoName} since it has no changes"
  fi
}

# fun: release repoFolder
# api: public
# txt: Performs the release on a given folder.
# opt: repoFolder: The repository folder.
# txt: Returns 0/TRUE always; but can exit with an error code.
# txt: If the function returns 0/TRUE, the variable RESULT will contain the new version.
# use: release /tmp/my_repo; echo "Release: ${RESULT}";
function release() {
  local _gitRepo="${1}"
  checkNotEmpty repoFolder "${_gitRepo}" 1

  logDebug -n "Pushing the commit in ${_gitRepo}"
  if gitPush "${_gitRepo}"; then
    logDebugResult SUCCESS "done"
  else
    logDebugResult FAILURE "failed"
    exitWithErrorCode GIT_PUSH_FAILED "${_gitRepo}"
  fi

  local _url
  if retrieveRepositoryUrl "${_gitRepo}"; then
    _url="${RESULT}"
  else
    exitWithErrorCode CANNOT_RETRIEVE_REPOSITORY_URL "${_gitRepo}"
  fi

  local _owner
  if extractOwnerFromGithubUrl "${_url}"; then
    _owner="${RESULT}"
  else
    exitWithErrorCode CANNOT_EXTRACT_OWNER_FROM_GITHUB_URL "${_url}"
  fi

  local _repo
  if extractRepoFromGithubUrl "${_url}"; then
    _repo="${RESULT}"
  else
    exitWithErrorCode CANNOT_EXTRACT_REPO_FROM_GITHUB_URL "${_url}"
  fi

  if ! nixBuild "${_gitRepo}"; then
    exitWithErrorCode NIX_BUILD_FAILED "${_gitRepo}"
  fi

  local _dir
  if extractParameterFromUrl "${_url}" "dir"; then
    _dir="${RESULT}"
  fi

  local _latestTag
  logDebug -n "Retrieving the latest remote tag of github:${_owner}/${_repo}, semver-compatible"
  if isNotEmpty "${_dir}" && retrieveLatestRemoteTagInGithubMatching "${_owner}" "${_repo}" "^${_dir}.*" "${GITHUB_TOKEN}"; then
    _latestTag="${RESULT}"
    logDebugResult SUCCESS "${_latestTag}"
  fi
  if isEmpty "${_latestTag}" && retrieveLatestRemoteTagInGithub "${_owner}" "${_repo}" "${GITHUB_TOKEN}"; then
    _latestTag="${RESULT}"
    logDebugResult SUCCESS "${_latestTag}"
  fi

  if isEmpty "${_latestTag}"; then
    local _error="${ERROR}"
    logDebugResult FAILURE "failed"
    if isNotEmpty "${_error}"; then
      logDebug "${_error}"
    fi
    exitWithErrorCode CANNOT_RETRIEVE_THE_LATEST_REMOTE_TAG_IN_GITHUB "${_url}"
  fi

  local _newVersion
  if incrementPatchVersion "${_latestTag}"; then
    _newVersion="${RESULT}"
  else
    exitWithErrorCode CANNOT_INCREMENT_THE_TAG_VERSION "${_latestTag}"
  fi

  logDebug -n "Creating a new tag ${_newVersion}' in ${_gitRepo}"
  if gitTag "${_gitRepo}" "${_newVersion}" "${TAG_MESSAGE}" "${GPG_KEY_ID}"; then
    logDebugResult SUCCESS "done"
  else
    local _error="${ERROR}"
    logDebugResult FAILURE "failed"
    if isNotEmpty "${_error}"; then
      logDebug "${_error}"
    fi
    exitWithErrorCode GIT_TAG_FAILED "${_gitRepo}"
  fi

  export RESULT="{ \"owner\": \"${_owner}\", \"repo\": \"${_repo}\", \"version\": \"${_newVersion}\", \"url\": \"${_url}\" }"
}

## Script metadata and CLI settings.
setScriptDescription "Creates a release tag of a given git repository"
setScriptLicenseSummary "Distributed under the terms of the GNU General Public License v3"
setScriptCopyright "Copyleft 2023-today Automated Computing Machinery S.L."

DW.getScriptName
SCRIPT_NAME="${RESULT}"
addCommandLineFlag "releaseName" "R" "The release name" MANDATORY EXPECTS_ARGUMENT
addCommandLineFlag "repository" "r" "The cloned repository" OPTIONAL EXPECTS_ARGUMENT
addCommandLineFlag "githubToken" "t" "The github token" OPTIONAL EXPECTS_ARGUMENT
addCommandLineFlag "gpgKeyId" "g" "The id of the GPG key" OPTIONAL EXPECTS_ARGUMENT
addCommandLineFlag "commitMessage" "c" "The commit message" OPTIONAL EXPECTS_ARGUMENT "Commit created with ${SCRIPT_NAME}"
addCommandLineFlag "tagMessage" "m" "The tag message" OPTIONAL EXPECTS_ARGUMENT "Tag created with ${SCRIPT_NAME}"
addCommandLineFlag "force" "f" "Force the release" OPTIONAL NO_ARGUMENT "${FALSE}"

checkReq jq
checkReq sed
checkReq grep

addError REPOSITORY_DOES_NOT_EXIST "Repository folder does not exist"
addError FOLDER_IS_NOT_A_GIT_REPOSITORY "Given folder is not a git repository"
addError GPG_KEY_ID_DOES_NOT_EXIST "GPG key id does not exist"
addError CANNOT_RETRIEVE_THE_LATEST_REMOTE_TAG_IN_GITHUB "Cannot retrieve the latest remote tag in github (or it's not semver-compatible)"
addError CANNOT_EXTRACT_OWNER_FROM_GITHUB_URL "Cannot extract the owner information from the url"
addError CANNOT_EXTRACT_REPO_FROM_GITHUB_URL "Cannot extract the repo information from the url"
addError CANNOT_INCREMENT_THE_TAG_VERSION "Cannot increment the tag version"
addError CANNOT_ADD_FLAKE_NIX "'git add flake.nix' failed in"
addError CANNOT_ADD_FLAKE_LOCK "'git add flake.nix' failed in"
addError GIT_COMMIT_FAILED "'git commit' failed in"
addError GIT_TAG_FAILED "'git tag' failed in"
addError GIT_PUSH_FAILED "'git push' failed in"
addError GIT_PUSH_TAGS_FAILED "'git push --tags' failed in"
addError NIX_BUILD_FAILED "'nix build' failed in"
addError NO_FLAKE_CHANGES_IN_REPO "Repository has no changes in flake files"

function dw_check_repo_cli_flag() {
  if ! folderExists "${REPOSITORY}"; then
    exitWithErrorCode REPOSITORY_DOES_NOT_EXIST "${REPOSITORY}"
  fi
}

function dw_check_gpgkeyid_cli_flag() {
  if isNotEmpty "${GPG_KEY_ID}" && ! checkGpgKeyIdKnown "${GPG_KEY_ID}"; then
    exitWithErrorCode GPG_KEY_ID_DOES_NOT_EXIST "${GPG_KEY_ID}"
  fi
}
# vim: syntax=sh ts=2 sw=2 sts=4 sr noet
