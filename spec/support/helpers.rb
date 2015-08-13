# Helper module with methods to support unit and integration tests
module Helpers
  def verify_git_repository(git_repo_local_path)
    system('git status 2>&1 1>/dev/null', chdir: git_repo_local_path)
  end

  def get_temp_dir_name(prefix)
    t = Dir.mktmpdir(prefix)
    FileUtils.rm_rf(t)
    t
  end
end
