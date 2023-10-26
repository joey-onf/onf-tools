#!/bin/bash

## --------------------------------------------------------------------
## Intent: Dispaly command usage
## --------------------------------------------------------------------
function __anonymous()
{
    cat <<EOH
Usage $0:
  --status         Query for patches with status=(open,merged,abandoned).
  ! --status foo   Exclude patches with status

[USAGE]
  $0 --status open,merged
     o Search for patches with status matching args
  $0 --status open --status merged
     o Search for patches with status matching args
  $0 ! --status merged --status abandonded
     o Search for patches not matching arguments

    return
}

__anonymous
unset __anonymous

# [EOF]
