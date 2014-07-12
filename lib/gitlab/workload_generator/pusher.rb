module Gitlab
  module WorkloadGenerator
    class Pusher
      def initialize(repo)
        @repo = repo
      end

      def run(max_commits_no = 5)
        prepare_next_push(max_commits_no)

        @repo.each_commit_to_push do |commit, is_last_commit|
          @to_be_pushed_count += 1

          if @to_be_pushed_count == @next_push_count || is_last_commit
            @repo.push(commit)
            prepare_next_push(max_commits_no)
          end
        end
      end

      private

      def prepare_next_push(max_commits_no)
        @to_be_pushed_count = 0
        @next_push_count    = rand(max_commits_no) + 1
      end
    end
  end
end
