# Asana team report

Outputs a table of Asana taks for a given team, divided into:

* Late
* Upcoming (Due within 5 days)
* Unassigned (not completed, but no owner)
* Recently completed

To use:

Set up some env vars (eg with direnv)

```
export ASANA_TOKEN=YOURTOKEN
export TEAM_ID=YOURTEAM
```

run `ruby report.rb`.