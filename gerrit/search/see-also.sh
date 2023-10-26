#!/bin/bash

## --------------------------------------------------------------------
## Intent: Dispaly command usage
## --------------------------------------------------------------------
function __anonymous()
{
    local -n ref=$1; shift

    ref+=('https://gerrit-review.googlesource.com/Documentation/user-search.html')
    return
}

##----------------##
##---]  MAIN  [---##
##----------------##
__anonymous $@
unset __anonymous

# [EOF]
