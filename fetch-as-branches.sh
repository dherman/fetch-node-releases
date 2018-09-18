#!/usr/bin/env bash

SCRIPT=$0

fetch_eprintf() {
  command printf "$1\n" 1>&2
}

fetch_usage() {
  fetch_eprintf "usage: $(basename $SCRIPT) major"
  fetch_eprintf '  major   major version number'
  fetch_eprintf
}

fetch_info() {
  local ACTION
  local DETAILS
  ACTION="$1"
  DETAILS="$2"
  command printf '\033[1;32m%12s\033[0m %s\n' "${ACTION}" "${DETAILS}" 1>&2
}

fetch_error() {
  command printf '\033[1;31mError\033[0m: ' 1>&2
  fetch_eprintf "$1"
}

fetch_warning() {
  command printf '\033[1;33mWarning\033[0m: ' 1>&2
  fetch_eprintf "$1"
  fetch_eprintf ''
}

fetch_get_versions_at() {
    local major
    major=$1
    #curl -s http://nodejs.org/dist/index.tab | awk '{ print $1; }' | fgrep "v${major}." | sed -e 's/v//' -e 's/\./ /g'
    curl -s http://nodejs.org/dist/index.tab | awk '{ print $1; }' | fgrep "v${major}." | sed -e 's/v//'
}

fetch_get_branch_list() {
    git branch --no-color | sed -e 's/^..//'
}

fetch() {
    local version
    local major
    local minor
    local patch
    local url
    local distrodir
    local filename

    major=$1
    for version in $(fetch_get_versions_at $major); do
        minor=$(echo $version | sed -e 's/^[0-9]*\.//' -e 's/\..*$//')
        patch=$(echo $version | sed -e 's/^[0-9]*\.[0-9]*\.//')

        if (fetch_get_branch_list | fgrep -q "v$version"); then
            fetch_info 'Skipping' "version $version (branch exists)"
            continue
        fi

        distrodir="node-v$version-darwin-x64"
        filename="$distrodir.tar.gz"
        url="http://nodejs.org/dist/v$version/$filename"

        fetch_info 'Creating' "branch v$version"
        git checkout -q --orphan "v$version"
        rm -rf ./$major

        fetch_info "Fetching" "v$version"
        curl -s "$url" > ./$filename || exit $?

        fetch_info "Unpacking" "v$version"
        mkdir -p ./$major/$minor
        tar xzf ./$filename || exit $?
        rm ./$filename
        mv $distrodir ./$major/$minor/$patch

        fetch_info "Committing" "branch v$version"
        git add ./$major/$minor/$patch
        git commit -q -a -m "v$version"
    done
}

if [ $# != 1 ]; then
  fetch_usage
  fetch_error 'no major version supplied'
  exit 1
fi

MAJOR=$1
fetch $MAJOR

#fetch_get_versions_at $MAJOR
