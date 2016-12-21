[![Build Status](https://travis-ci.org/AVGTechnologies/package_provider.svg)](https://travis-ci.org/AVGTechnologies/package_provider)
[![Code Climate](https://codeclimate.com/github/AVGTechnologies/package_provider/badges/gpa.svg)](https://codeclimate.com/github/AVGTechnologies/package_provider)
[![License](license-apache-2.svg)](https://github.com/AVGTechnologies/package_provider/blob/master/LICENCE)

Package provider
================
Service for obtaining zip packages from git repositories  
based on user specification. You can download specific  
folders from multiple repositories and combine them  
into one zip file.

Endpoints
---------
```
GET  /api/v1/uptime

GET  /repositories
POST /repositories/reload
GET  /repositories/:alias

POST /packages/download
GET  /packages/download/:package_hash
```

Request for package
-------------------

Plain text format (make sure you set text/plain content type)
```
repistory_url|branch:treeish(folder_name_in_repository>folder_name_in_archive)
```

Json format
```
[
  {
     repository: repository_url,
     commit: treeish,
     branch: branch,
     folderOverride: [
          { source: folder_name_in_repository, destinationOverride: folder_name_in_archive }
     ]
  }
]
```
Where branch or treeish is required. Folder override part is not required. If you don't specify folder override, that config settings are used. You can combine multiple repositories and folders from repositories. You can use
repository alias insted of repository url. List of aliases is in config/repository_aliases.yml file. The whole repository could be returned when source folder override is specified as `/**`, for example: `repo|master(/**>foobar)`


Prerequisites for development on windows machine
-----------------------------
* Vagrant installed (https://www.vagrantup.com/) and added to PATH
* Path to SSH added to PATH

FAQ
---
1. How to remove all scheduled jobs?

     require 'sidekiq/api'
     Sidekiq::Queue.new('package_packer').clear
     Sidekiq::Queue.new('clone_repository').clear

     if jobs are allready running then use
     Sidekiq::RetrySet.new.clear
     Sidekiq::ScheduledSet.new.clear
