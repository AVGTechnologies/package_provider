Package provider documentation
==============================
This project is self-standing service that provides packages in ZIP
format. Packages can be mixed from various git repositories and its content.
The package content is specified by incoming requests.


Clases
-------

### PackageProvider::Repository
Class maintaining git operations such as #clone, #fetch and #checkout

### PackageProvider::Parser
Class responsible for parsing requests

### PackageProvider::RepositoryRequest
Class representing part of package request

Request format
--------------
### json

### text
<repository>|<branch>:<commitHash>(<folderOverride>)
Reposiory is mandatory. You can specify branch or commit hash. If you
specify only branch then latest commit will be used. Last section
folder override is described below

### Folder override format
Folder override specification support same format as git sparse checkout
file. See the sparse-checkout file specification for available options
(same as [.gitignore](http://git-scm.com/docs/gitignore))
Examples:
  /logs - to get logs folder content from specified repository
  \*.log - get all log files in repository
