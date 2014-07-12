require 'optparse'

require 'gitlab'
require 'octokit'

require 'gitlab/workload_generator/pusher'
require 'gitlab/workload_generator/local_repo'

module Gitlab
  module WorkloadGenerator
    class PusherCli
      LANGS = %w[javascript java php c css python ruby objective-c]

      def initialize(env)
        @octokit_client = Octokit::Client.new
        @gitlab_client  = Gitlab.client(endpoint: env['GITLAB_API_ENDPOINT'], private_token: env['GITLAB_API_PRIVATE_TOKEN'])
        @credentials    = Rugged::Credentials::UserPassword.new(username: env['GITLAB_USERNAME'], password: env['GITLAB_PASSWORD'])
      end

      def run
        loop do
          repos = if @octokit_client.last_response && @octokit_client.last_response.rels[:next]
                    @octokit_client.last_response.rels[:next].get.data
                  else
                    @octokit_client.search_repos("#{('a'..'z').to_a.sample} size:>=#{rand(1..50)}000 language:#{LANGS.sample}")
                  end

          repos.items.each do |repo|
            gitlab_response = @gitlab_client.create_project(repo.name) rescue next
            local_repo      = Gitlab::WorkloadGenerator::LocalRepo.new(repo.clone_url, gitlab_response.http_url_to_repo, @credentials)

            Gitlab::WorkloadGenerator::Pusher.new(local_repo).run
          end
        end
      end
    end
  end
end
