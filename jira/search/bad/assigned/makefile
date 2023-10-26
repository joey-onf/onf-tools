# -*- makefile -*-

BROWSER ?= opera

all:
	$(BROWSER) --url 'https://jira.opennetworking.org/issues/?jql=assignee=currentUser()%20AND%20(resolution%20IS%20EMPTY)' >/dev/null 2>/dev/null &

fail:
	./cmd.sh

# [EOF]
