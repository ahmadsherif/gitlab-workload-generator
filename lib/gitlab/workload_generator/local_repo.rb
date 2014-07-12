require 'rugged'

module Gitlab
  module WorkloadGenerator
    class LocalRepo
      CLONE_AT_PATH      = '/tmp'
      SOURCE_BRANCH_NAME = '__src__'
      GITLAB_REMOTE_NAME = 'gitlab'

      def initialize(source_repo_url, gitlab_repo_url, credentials)
        @source_repo_url = source_repo_url
        @gitlab_repo_url = gitlab_repo_url
        @credentials     = credentials

        setup
      end

      def each_commit_to_push
        commits_walker(master_branch_last_commit, source_branch_last_commit).reverse_each do |commit|
          yield commit, no_more_commits_to_push?
        end
      end

      def push(commit)
        create_source_branch_at_commit(commit)
        push_to_remote_branch
      end

      private

      def setup
        add_gitlab_remote
        create_remote_branch
      end

      def add_gitlab_remote
        repo.remotes.create(GITLAB_REMOTE_NAME, @gitlab_repo_url) rescue nil
      end

      def create_remote_branch
        return if repo.remotes[GITLAB_REMOTE_NAME] && repo.remotes[GITLAB_REMOTE_NAME].ls(credentials: @credentials).any?

        create_source_branch_at_commit(repo_first_commit)
        push_to_remote_branch
      end

      def repo_first_commit
        commits_walker(repo.last_commit).select { |commit| commit.parents.empty? }.first
      end

      def commits_walker(from_commit, to_commit = nil)
        walker = Rugged::Walker.new(repo)
        walker.push(from_commit)
        walker.hide(to_commit) if to_commit
        walker.simplify_first_parent
        walker
      end

      def push_to_remote_branch
        repo.push(GITLAB_REMOTE_NAME, ["refs/heads/#{SOURCE_BRANCH_NAME}:refs/heads/master"], credentials: @credentials)
      end

      def repo
        @repo ||= begin
                    Rugged::Repository.new(repo_clone_path)
                  rescue Rugged::OSError
                    Rugged::Repository.clone_at(@source_repo_url, repo_clone_path)
                  end
      end

      def repo_clone_path
        @repo_clone_path ||= File.join(CLONE_AT_PATH, repo_name)
      end

      def repo_name
        @repo_name ||= @source_repo_url.gsub(/\/?\.git\/?/, '').gsub(/^.*\//, '')
      end

      def create_source_branch_at_commit(commit)
        repo.branches.delete(SOURCE_BRANCH_NAME) rescue nil
        repo.create_branch(SOURCE_BRANCH_NAME, commit)
      end

      def source_branch_last_commit
        repo.branches[SOURCE_BRANCH_NAME].target
      end

      def master_branch_last_commit
        repo.branches['master'].target
      end

      def no_more_commits_to_push?
        source_branch_last_commit == master_branch_last_commit
      end
    end
  end
end
