require 'tmpdir'
require 'open3'
require 'benchmark'

# Namespace that handles git operations for PackageProvider
module PackageProvider
  # Class for cloning remote or local git repositories
  # and checkouting specified folders
  class Repository
    attr_reader :repo_url, :repo_root

    CLONE_SCRIPT = File.join(PackageProvider.root, 'lib', 'scripts', 'clone.sh')
    INIT_SCRIPT = File.join(PackageProvider.root, 'lib', 'scripts', 'init_repo.sh')

    class InvalidRepoPath < ArgumentError
    end

    # general git process exception class
    class GitError < StandardError
      attr_reader :exit_code

      def initialize(exit_code)
        super
        @exit_code = exit_code
      end
    end

    class CannotInitRepo < GitError
    end

    class CannotFetchRepo < GitError
    end

    class CannotCloneRepo < GitError
    end

    class << self
      def temp_prefix=(tp)
        @temp_prefix_internal = tp
      end

      def temp_prefix
        @temp_prefix_internal || "package_provider_repo_#{Process.pid}"
      end

      def commit_hash(req)
        fail ArgumentError, 'Missing branch' unless req.branch
        logger = PackageProvider.logger
        logger.info("Resolving commit hash for #{req.to_tsd}")

        params = ['git', 'ls-remote', '--exit-code', req.repo, '-h', "refs/heads/#{req.branch}"]
        std_out, std_err, status = Open3.capture3({}, *params, chdir: '/tmp')

        if status.success?
          logger.info("Commit hash for #{req.to_tsd}: #{std_out.split.first}")
          return std_out.split.first
        else
          logger.error("Resolving commit hash failed! code: #{status.exitstatus} err: #{std_err}")

          fail GitError, git_error_message(req.repo, req.branch, status.exitstatus)
        end
      end

      private

      def git_error_message(repo, branch, exit_code)
        "Branch #{branch} not found" if exit_code == 2
        "Unable to retrieve commit hash for #{repo}|#{branch}"
      end
    end

    def initialize(git_repo_url, git_repo_local_cache_root = nil)
      if git_repo_local_cache_root && !Dir.exist?(git_repo_local_cache_root)
        fail InvalidRepoPath, "Directory #{git_repo_local_cache_root.inspect} does not exists"
      end

      @repo_url = git_repo_url
      @repo_root = Dir.mktmpdir(self.class.temp_prefix)

      init_repo!(git_repo_local_cache_root)
    end

    def logger
      PackageProvider.logger
    end

    def clone(dest_dir, treeish, paths, use_submodules = false)
      fail InvalidRepoPath, "Folder #{dest_dir} exists" if Dir.exist?(dest_dir)

      logger.debug "clonning repo #{repo_root}: [dest_dir: #{dest_dir.inspect}, " \
        "treeish: #{treeish.inspect}, use_submodules: #{use_submodules.inspect}]"

      begin
        FileUtils.mkdir_p(dest_dir)
        fetch!

        fill_sparse_checkout_file(paths)

        command = compose_clone_command(dest_dir, treeish, use_submodules)

        status, stderr = run_command({ 'ENV' => PackageProvider.env }, command, change_pwd, 'clone')

        unless status.success?
          fail CannotCloneRepo.new(status.exitstatus), stderr
        end

        dest_dir
      rescue => err
        FileUtils.rm_rf(dest_dir) rescue nil
        logger.error "Cannot clone repository #{repo_root}: #{err}"
        raise
      end
    end

    def destroy
      FileUtils.rm_rf(@repo_root)
    end

    private

    def compose_clone_command(dest_dir, treeish, use_submodules)
      command = [CLONE_SCRIPT]
      command << '--use-submodules' if use_submodules
      command.concat [repo_root, dest_dir, treeish]
    end

    def metriks_key
      path = begin
        URI.parse(@repo_url).path
      rescue
        @repo_url[/^.+@?[\w\d\.-]+:(.*)$/, 1]
      end

      path.sub!(/\.git\Z/, '')
      path.gsub!(/\W/, '_')
      path.gsub(/\A_/, '')
    end

    def change_pwd
      { chdir: repo_root }
    end

    def init_repo!(git_repo_local_cache_root)
      status, stderr = run_command(
        { 'ENV' => PackageProvider.env },
        [INIT_SCRIPT, repo_url, git_repo_local_cache_root || ''],
        change_pwd,
        'init_repo'
      )
      fail CannotInitRepo.new(status.exitstatus), stderr unless status.success?
    end

    def fetch!
      status, stderr = run_command({}, ['git', 'fetch', '--all'], change_pwd, 'fetch')
      fail CannotFetchRepo.new(status.exitstatus), stderr unless status.success?
    end

    def fill_sparse_checkout_file(paths)
      paths = ['/**'] if paths.nil?
      path = File.join(repo_root, '.git', 'info', 'sparse-checkout')

      logger.debug "Setting sparse-checkout to: #{paths.join("\n")}"
      File.open(path, 'w+') do |f|
        f.puts paths.join("\n")
      end
    end

    def run_command(env_hash, params, options_hash, operation)
      logger.debug "Running shell command: #{params.inspect}"
      o = e = s = nil

      time = Benchmark.realtime do
        o, e, s = Open3.capture3(env_hash, *params, options_hash)
      end

      if s.success?
        log_result('stdout', operation, params, o)
        log_result('stderr', operation, params, e)
        Metriks.timer("packageprovider.repository.#{operation}.#{metriks_key}").update(time)
      else
        log_error(params, operation, o, e)
        Metriks.meter("packageprovider.repository.#{operation}.#{metriks_key}.error").mark
      end
      [s, e]
    end

    def log_result(std, operation, params, result)
      logger.info "Command[#{operation}] #{params.inspect}" \
        "returns #{result.inspect} on #{std}" unless result.empty?
    end

    def log_error(params, operation, o, e)
      logger.error "Command[#{operation}] #{params.inspect} failed! " \
        "STDOUT: #{o.inspect}, STDERR: #{e.inspect}"
    end
  end
end
