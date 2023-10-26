#!/bin/bash

## -----------------------------------------------------------------------
## Intent: Helper method
## -----------------------------------------------------------------------
## Usage : local path="$(join_by '/' 'lib' "${fields[@]}")"
## -----------------------------------------------------------------------
function join_by()
{
    local d=${1-} f=${2-}; if shift 2; then printf %s "$f" "${@/#/$d}"; fi;
}

url='https://jira.opennetworking.org/issues/'
declare -a args=()

declare -a jql=()
# jql+=('(text%20~%20"alex")')
# jql+=('(assignee=currentUser())')
jql+=('(reporter=currentUser())')
jql+=('AND')
jql+=('(text%20~%20"nodes")')
jql+=('AND')
jql+=('(resolution%20IS%20EMPTY)')
jql_args=$(join_by '%20' "${jql[@]}")

# args+=('--url' "${url}?jql=(text%20~%20"alex")%20AND%20(resolution%20IS%20EMPTY)")
args+=('--url' "${url}?jql=${jql_args}")

opera "${args[@]}" >/dev/null 2>/dev/null &

# [EOF]

