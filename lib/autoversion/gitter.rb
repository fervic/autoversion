require 'git'

module Autoversion
  class Gitter

    class DirtyStaging < Exception 
    end
    
    class NotOnStableBranch < Exception 
      def initialize(msg)
        super(msg)
      end
    end

    def initialize path, config
      @path = path
      @config = config
      @repo = Git.open(path)
    end

    def ensure_cleanliness!
      if @config[:actions].include?(:commit)
        raise DirtyStaging unless dir_is_clean?
      end
    end

    def ensure_valid_branch! versionType
      raise NotOnStableBranch.new(@config[:stable_branch]) if versionType == :major && !on_stable_branch?
    end

    def dir_is_clean?
      sum = gitstatus_untracked_workaround.length +
            @repo.status.added.length +
            @repo.status.changed.length +
            @repo.status.deleted.length

      sum == 0
    end

    def on_stable_branch?
      @repo.current_branch == @config[:stable_branch].to_s
    end

    def commit! versionType, currentVersion
      return false unless @config[:actions].include?(:commit) 
   
      write_commit currentVersion
      write_tag currentVersion if @config[:actions].include?(:tag)
    end

    private

    def write_commit version
      @repo.add '.'
      @repo.commit "#{@config[:prefix]}#{version}"
    end

    def write_tag version
      @repo.add_tag "#{@config[:prefix]}#{version}"
    end

    def gitstatus_untracked_workaround
      git_cmd = "git --work-tree=#{@repo.dir} --git-dir=#{@repo.dir}/.git " +
                "ls-files -o -z --full-name --exclude-standard"
      `#{git_cmd}`.split("\x0")
    end

  end
end

