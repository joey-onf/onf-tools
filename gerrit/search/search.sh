#!/bin/bash
## --------------------------------------------------------------------
## Intent: Contstruct queries to search for patches in gerrit
## --------------------------------------------------------------------

##-------------------##
##---]  GLOBALS  [---##
##-------------------##
declare -g -a query_args=()
query_args+=('owner:self')

declare -g -a urls=()
declare -g -x BROWSER="${BROWSER:=/usr/bin/opera}"
declare -g -i negate=0

##----------------##
##---]  INIT  [---##
##----------------##
{
    declare -g pgm="$(readlink --canonicalize-existing "$0")"
    declare -g pgmbin="${pgm%/*}"
#    declare -g pgmroot="${pgmbin%/*}"
    declare -g pgmroot="${pgmbin%}"
    declare -g pgmname="${pgm%%*/}"

    readonly pgm
    readonly pgmbin
    readonly pgmroot
    readonly pgmname
}

## --------------------------------------------------------------------
## --------------------------------------------------------------------
function error()
{
    echo "ERROR ${FUNCNAME[1]}: $@"
    exit 1
}

## -----------------------------------------------------------------------
## Intent: Helper method
## -----------------------------------------------------------------------
## Usage : local path="$(join_by '/' 'lib' "${fields[@]}")"
## -----------------------------------------------------------------------
function join_by()
{
    local d=${1-} f=${2-}; if shift 2; then printf %s "$f" "${@/#/$d}"; fi;
}

## -----------------------------------------------------------------------
## Intent:
## -----------------------------------------------------------------------
function add_op()
{
    local -n ref_add_op=$1; shift

    while [ $# -gt 0 ]; do
        val="$1"; shift

        case "$val" in
            [aA][nN][dD]) ref_add_op+=('AND')  ;;
                [oO][rR]) ref_add_op+=('OR')   ;;
            [nN][oO][tT]) ref_add_op+=('NOT')  ;;
                       *) ref_add_op+=("$val") ;;
        esac
    done

    return
}

# -----------------------------------------------------------------------
# %40=@, %2540 => (%40 + encoded percent)
# -----------------------------------------------------------------------
# https://gerrit.opencord.org/q/onf-make
# https://gerrit.opencord.org/q/project:voltha-docs+branch:master
# https://gerrit.opencord.org/q/owner:joey%2540opennetworking.org
# https://gerrit.opencord.org/q/+status:open+AND+(owner:self+or+owner:ren%2540stimpy.com)
#   o status:open AND (owner:rajesh@abc.com OR owner:ramesh@abc.com OR owner:kumar@abc.com)

# Any operator can be negated by prefixing it with -, for example -is:starred is the exact opposite of is:starred and will therefore return changes that are not starred by the current user.

# -----------------------------------------------------------------------
# is:open label:Code-Review+2 label:Verified+1 NOT label:Verified-1 NOT label:Code-Review-2
# is:open label:Code-Review=ok label:Verified=ok
# Matches changes that are ready to be submitted according to one common label con# figuration. (For a more general check, use is:submittable.)
# -----------------------------------------------------------------------
# label:Code-Review=2
# label:Code-Review=+2
# label:Code-Review+2
# -----------------------------------------------------------------------
function add_label()
{
    local -n ref=$1; shift

    add_op ref 'AND' 'label:Code-Review<2'
    return
}

# -----------------------------------------------------------------------
# Intent: Add a date conditional
#   --age 7d      # patches last modified over a week ago
#   ! --age -2d   # search for patches modified within the last 2 days
# -----------------------------------------------------------------------
function add_age()
{
    local -n ref=$1; shift
    local val="$1";  shift

    case "$val" in
        s|sec|second|seconds) ;;
        m|min|minute|minutes) ;;
        h|h|hour|hours)       ;;
        d|day|days)           ;;
        w|week|weeks)         ;;
        mon|month|months)     ;;
        y|year|years)         ;;
        *) error "--age: try one of sec min hr day week month year" ;;
    esac

    add_op ref 'AND' 'label:Code-Review<2'
    return
}

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
function add_result_limit()
{
    local -n ref=$1; shift
    local val="$1"; shift

    add_op ref 'AND' "limit:$val"
    return
}

## -----------------------------------------------------------------------
## Intent:
## -----------------------------------------------------------------------
## https://gerrit-review.googlesource.com/Documentation/user-search.html
## -----------------------------------------------------------------------
function do_query()
{
    # declare -a query_args=()
    query_args+=('owner:self')
    # query_args+=('-age:2d')
    # query_args+=('status:open')

    # https://gerrit.opencord.org/q/owner:self+AND+NOT(status:merged+OR+status:closed)
    declare -a status_not=()
    status_not+=('status:closed')
    status_not+=('status:merged')

    if [[ ${#status_not[@]} -gt 0 ]]; then
        declare -a status=()
        local tmp="$(join_by '+OR+' "${status_not[@]}")"
        # status+=("($tmp)")
        add_op status 'AND' 'NOT' "($tmp)"
        query_args+=("${status[@]}")
    fi

    add_label query_args
    # add_limit query_args
    
    return
}

## -----------------------------------------------------------------------
## Intent: Sub-split array elements on delimiter
## -----------------------------------------------------------------------
function split_on_delim()
{
    local -n ref="$1"; shift
    local delim="$1"; shift

    local -a todo=("${ref[@]}")
    ref=()
    local val
    for val in "${todo[@]}";
    do
        readarray -d"$delim" -t tmp < <(printf '%s' "$val")
        ref+=("${tmp[@]}")
    done

    return
}

## -----------------------------------------------------------------------
## Intent: Sub-split array elements on delimiter
## -----------------------------------------------------------------------
function add_prefix()
{
    local -n ref="$1"; shift
    local pref="$1"; shift

    local -a todo=("${ref[@]}")
    ref=()
    local val
    for val in "${todo[@]}";
    do
        ref+=("${pref}:${val}")
    done

    return
}

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
function append_and_or()
{
    local -n ref="$1"   ; shift
    local prefix="$1"   ; shift
    local -n ref_and=$1 ; shift
    local -n ref_or=$1  ; shift

    ## ------------------------------------------------
    ## Append accumulated switch values to query string
    ## ------------------------------------------------
    if [[ ${#ref_and[@]} -gt 0 ]]; then
        split_on_delim ref_and ','
        add_prefix ref_and "$prefix"
        local -a buffer="$(join_by 'AND' ${ref_and[@]})"
        ref+=('AND' "(${buffer[@]})")
    fi

    if [[ ${#ref_or[@]} -gt 0 ]]; then
        split_on_delim ref_and ','
        add_prefix ref_and "$prefix"
        local -a buffer="$(join_by 'OR' ${ref_or[@]})"
        ref+=('OR' "(${buffer[@]})")
    fi

    return
}

##----------------##
##---]  MAIN  [---##
##----------------##

if [[ $# -eq 0 ]]; then
    declare -a args=()
    args+=('!' '--status' 'merged')
    args+=('!' '--status' 'abandoned')
    set -- "${args[@]}"
#    set -- --help
fi

set -- $* '!--done--!'

declare -a and=()
declare -a or=()
declare -a not_and=()
declare -a not_or=()

declare -a gather=()

readarray -d'-' -t parsed < <(printf '%s' "$1")
last_arg="$1"
last_stem="${parsed[0]}"
while [ $# -gt 0 ]; do
    arg="$1"; shift
    [[ -v debug ]] && echo "** argv=[$arg] [$*]"

    readarray -d'-' -t parsed < <(printf '%s' "$arg")
    stem="${parsed[0]}"
    
    if [[ ${#last_arg} -lt 3 ]]; then
        :
    elif [[ "$last_stem" != "$stem" ]]; then
        key="${last_stem:2}"
        [[ $negate -ne 0 ]] && key="-${key}"

        append_and_or query_args "$key" and or

        and=()
        or=()
        not_and=()
        not_or=()
        
        negate=0
    fi

    case "$arg" in
        !--done--!) break ;;
        
        !) negate=1; continue ;;

        ##-----------------##
        ##---]  MODES  [---##
        ##-----------------##
        --debug)   declare -g -i debug=1   ;;
        --dry-run) declare -g -i dry_run=1 ;;

        --not)
            arg="$1"; shift
            case "$arg" in
                # https://gerrit.opencord.org/q/owner:self+AND+NOT(status:merged+OR+status:closed)
                abandoned) add_op query_args 'NOT' "(status:abandoned)" ;;
                merged) add_op query_args 'NOT' "(status:merged)" ;;
                *) error "Detected unknown --not token [$arg]" ;;
            esac
            ;;
    
        ##----------------------##
        ##---]  ONE-LINERS  [---##
        ##----------------------##
        --help*)
            readarray -d'-' -t tmp < <(printf '%s' "$arg")

            if [ ${#tmp[@]} -gt 1 ]; then
                topic="$pgmbin/help/${tmp[1]}.sh"
                if [ -e "$topic" ]; then
                    source "$topic"
                    exit 0
                fi
            fi
            source "$pgmbin/help.sh"; exit 0 
           ;;

        --see-also) source "$pgmbin/see-also.sh" urls ;;

        --query) do_query ;;

        --*age*)
            last_stem="$stem"
            last_arg="$arg"
            arg="$1"; shift

            case "$last_arg" in
                --not*) not+=("$arg")  ;;
                --or*) or+=("$arg")  ;;
                  --*) and+=("$arg") ;;
            esac
            ;;

        --*status*)
            readarray -d'-' -t tmp < <(printf '%s' "${arg:2}")

            last_arg="$arg"
            last_stem="${arg[0]}"

            arg="$1"; shift
            declare -p negate
            [[ $negate -ne 0 ]]    && gather+=('NOT')
            declare -p gather
            declare -p tmp
            [[ ${#tmp[@]} -gt 1 ]] && gather+=("${tmp[1]^^}") # upppercase
            declare -p gather
            gather+=("$arg")
            declare -p gather
            error "OUTA HERE"
            ;;

        --limit)
            val="$1"; shift
            add_result_limit query_args "$val" ;;
        
        ## Catchall
        *) error "Detected unknown argument $arg" ;;
    esac

done

## Launchers
[[ ${#urls[@]} -gt 0 ]] && { "$BROWSER" "${urls[@]}"; }

if [[ ${#query_args[@]} -gt 0 ]]; then
    # https://gerrit.opencord.org/q/-age:2d,+owner:self+status:open
    # query_args+=('is:owner'
    base='https://gerrit.opencord.org/q'
    args="$(join_by '+' "${query_args[@]}")"
    url="${base}/${args}"

    [[ -v debug ]] && echo "URL: $url"
    "$BROWSER" "$url" >/dev/null 2>/dev/null &
fi

# [EOF]
