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

after "deploy:check:make_linked_dirs", "pingity_bot:upload_env"

namespace :pingity_bot do
  task :upload_env do
    on roles(:pingitybot_vagrant) do
      execute! "sudo systemctl enable pingitybot.service && sudo systemctl start pingitybot.service"
    end
  end
end

append :linked_files,
  '.env'
#   'config/database.yml',
#   'config/rmq.yml',
#   'config/api_config.yml',
#   'config/event_queue.yml'

set :keep_releases, 5

set :ssh_options, user: 'vagrant'
set :ssh_options, { :forward_agent => true }
