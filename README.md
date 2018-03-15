# foreman_release

A set of helpful scrips that aims to make [Foreman release process](http://projects.theforeman.org/projects/foreman/wiki/Release_Process) more automated.

## How to use

* Clone this repo
* create VERSION and GPGKEY files with release version and gpg key for a release. See the example files.
* you will need ruby and ansible to run certain commands

## signing.rb

Downloads the core tarballs from downloads.theforeman.org, signs them and uploads signatures. Aims to replace step 9 when [tagging a release](http://projects.theforeman.org/projects/foreman/wiki/Release_Process#Tagging-a-release)

Requires config.yml with the following entries:

* :theforeman_user - user name on theforeman.org
* :gpg_homedir - path to where the gpg keys are located

During the script execution, you will be prompted for gpg keys passphrase and password for theforeman.org
