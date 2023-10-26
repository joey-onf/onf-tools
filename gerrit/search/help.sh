#!/bin/bash

## --------------------------------------------------------------------
## Intent: Dispaly command usage
## --------------------------------------------------------------------
function __anonymous()
{
    cat <<EOH
Usage: $0
  --age, --or-age    Filter search by time last modified.
  --status           Query for patches with status

[MODES]
  --debug            Enable script debug mode
  --dry-run          Simulate

[BOOLEAN]
  !                  Negate/exclude the next operator (! --owner me)

[MISC]
  --help-{topic}     Display extended switch help (--help-status)
  --see-also         View resource documentation in a browser

[USAGE]
  $0 --status open,merged
     o Search for status in list
  $0 --status open --age -2d
     o Search for patches modified within the last 2 days.
  $0 --status open --age 7d --limit 5
     o Display 5 patches last modified over one week ago.  
  $0 ! --status merged
     o Exclude merged patches from search results

  $0 --not merged
     o Search for NOT(status:merged)

EOH

    return
}

__anonymous
unset __anonymous

# [EOF]
