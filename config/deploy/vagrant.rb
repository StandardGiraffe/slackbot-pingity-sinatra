role 'app', %w[
  pingitybot-vagrant
]

set :branch, ENV['BRANCH'] || 'master'

set :ssh_options, user: 'vagrant'
