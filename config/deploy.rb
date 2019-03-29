# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "pingitybot"
set :repo_url, "git@github.com:StandardGiraffe/slackbot-pingity-sinatra.git"

set :format, :airbrussh
set :format_options,
    command_output: true,
    log_file: "log/capistrano.log",
    color: :auto, truncate: :auto

set :deploy_to, "/app/pingitybot"

after "deploy:symlink:release", "pingitybot:start_pingitybot_service"

namespace :pingitybot do
  task :start_pingitybot_service do
    on roles(:app) do
      execute "sudo systemctl enable pingitybot.service && sudo systemctl start pingitybot.service"
    end
  end
end

append :linked_files,
  '.env'

set :keep_releases, 5

set :ssh_options, user: 'vagrant'
set :ssh_options, { :forward_agent => true }
