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

append :linked_files,
  '.env'
#   'config/database.yml',
#   'config/rmq.yml',
#   'config/api_config.yml',
#   'config/event_queue.yml'

set :keep_releases, 5

set :ssh_options, user: 'vagrant'
set :ssh_options, { :forward_agent => true }
