# foreman_release

A set of scripts to make releases of Foreman more automated.

### release_issues.rb

Helps with formatting issues for the release notes. Because Redmine API does not provide any information about releases, a few manual steps are necessary.

1. Go to Redmine and filter issues with the following: Release is x.y.z, Tracker is Feature, Status is closed
2. Export in CSV (bottom right on the page), save into your checkout of foreman_release
3. Make sure the encoding is UTF-8, change the '#' character on the first line into 'id' ('#' cannot be turned into a Symbol, so the whole column is skipped when reading the file)
4. run the script, content of newly created issues_out.md can be used for release notes
