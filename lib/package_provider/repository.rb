require 'tmpdir'
require "open3"

module PackageProvider
  class Repository

    attr_reader :repo_url, :repo_root

    class InvalidRepoPath < ArgumentError
    end

    def initialize(git_repo_url, git_repo_local_root = nil)

      if git_repo_local_root
        raise InvalidRepoPath, "Folder #{git_repo_local_root} does not exists" unless Dir.exists?(git_repo_local_root)
      end

      @repo_url = git_repo_url
      @repo_root = Dir.mktmpdir('pp_repo_')

      clone!(git_repo_local_root)
    end

    def clone(dest_dir, treeish, options)
      fetch!

      if !Dir.exists?(dest_dir)

        args = ["git", "--git-dir=#{repo_root}" ,"config core.sparsecheckout true"]
        o, e, s = Open3.capture3(args.join(' '))
        processOutput(o, e, s, 'set sparse chekout')

        path = File.join()
        system("echo ppc/ > .git/info/sparse-checkout")
        #FileName="git";
        #Arguments="-c http.sslverify=false archive --format zip -0 --output=C:\cache_stage\packages-parts\4709073bacdd2437c075632b7ca1b680\_TEMP_\ff8757fe-b58a-411c-8266-4c5a368c6554.zip d74fb192451426d9e5801b65d1e72c99914b79bd automation";
      end

      dest_dir
    end

    def fetch(treeish = nil)
      fetch!
    end

    def destroy
      FileUtils.rm_rf(@repo_root)
    end

    private

    def clone!(git_repo_local_root)
      repo_source = git_repo_local_root || repo_url

      cmd = ["git","-c http.sslverify=false","clone -s -l --no-hardlinks --bare", repo_source, repo_root]
      o, e, s = Open3.capture3(cmd.join(' '))
      processOutput(o, e, s, 'clone')

      if git_repo_local_root
        o, e, s = Open3.capture3({}, 'git', 'remote', 'set-url', 'origin', repo_url, chdir: '...')
        PackageProvider.logger.debug o
        PackageProvider.logger.error e
      end
    end

    def fetch!
      cmd = ["git","--git-dir=#{repo_root}","fetch --all"]
      o, e, s = Open3.capture3(cmd.join(' '))
      processOutput(o, e, s, 'fetch')
    end

    def processOutput(stdout, stderr, status, action)
      #puts action
      #puts e
      #puts o
      #puts s
    end

  end
end
