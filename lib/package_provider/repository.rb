require 'tmpdir'
require "open3"

module PackageProvider
  class Repository

    attr_reader :repo_ur, :repo_folder, :local_git_repo_folder

    class InvalidRepoPath < ArgumentError
    end

    def initialize(repo_url, local_git_repo_folder = nil)
      @repo_url = repo_url
      @repo_folder = Dir.mktmpdir('pprepo_')

      if local_git_repo_folder
        @local_git_repo_folder = local_git_repo_folder
        raise InvalidRepoPath, 'Folder #{@local_git_repo_folder}' unless Dir.new(@local_repo_rot_folder).exists?
      end

      clone!
    end

    def clone(dest_folder)
      dest_folder
    end

    def fetch()
      fetch!
    end

    def destroy
      FileUtils.rm_rf(@repo_folder)
    end

    private



    def fetch!

      Dir.chdir(full_repo_path) do
        Open3.popen3("git fetch --all") do |stdin, stdout, stderr, wait_thr|
          pid = wait_thr.pid # pid of the started process.
          exit_status = wait_thr.value # Process::Status object returned.
        end
      end
    end

    def clone!
      params = ['clone', @repo_url, @repo_folder]

      repo_source = @local_git_repo_folder || @repo_url
      path = full_repo_path

      puts path

      Open3.popen3("git -c http.sslverify=false clone #{repo_source} #{path}") do |stdin, stdout, stderr, wait_thr|
        pid = wait_thr.pid # pid of the started process.
        exit_status = wait_thr.value # Process::Status object returned.
      end

      #TODO set origin if cloned from folder
    end

    def full_repo_path
       File.join(@repo_folder, "cloned_repo")
    end

  end

end
