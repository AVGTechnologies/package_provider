[![Build Status](https://travis-ci.org/AVGTechnologies/package_provider.svg)](https://travis-ci.org/AVGTechnologies/package_provider)
[![Code Climate](https://codeclimate.com/github/AVGTechnologies/package_provider/badges/gpa.svg)](https://codeclimate.com/github/AVGTechnologies/package_provider)

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

GET /repositories
POST  /repositories/reload
GET /repositories/:alias

POST  /packages/download
GET /packages/download/:package_hash
```
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
