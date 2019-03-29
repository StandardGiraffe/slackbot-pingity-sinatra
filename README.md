# PingityBot for Slack

PingityBot integrates [Pingity](https://pingity.com) web resource analysis services with Slack, allowing team members to display analysis results directly in-channel, and to monitor particular resources for changes over a desired time period.

## Usage
`/ping` and `/monitor` details go here

## Installation

### Building Vagrant Machine
Clone PingityBot and provision a Vagrant machine using the included `Vagrantfile`:
```bash
<home:> ...$ git clone git@github.com:StandardGiraffe/slackbot-pingity-sinatra.git
<home:> ...$ cd slackbot-pingity-sinatra
<home:> .../slackbot-pingity-sinatra$ vagrant up
<home:> .../slackbot-pingity-sinatra$ vagrant ssh
```
Once inside, create a landing directory for the deployed PingityBot:
```bash
<vagrant:> /app# mkdir -p pingitybot/releases pingitybot/shared
<vagrant:> /app# chown -R vagrant:vagrant pingitybot
```

Install Ruby, Rack, Bundler, and compilers:
```bash
<vagrant:> ~# apt install ruby
<vagrant:> ~# apt install ruby-dev
<vagrant:> ~# gem install rack
<vagrant:> ~# gem install bundler
<vagrant:> ~# apt install gcc
<vagrant:> ~# apt install make
<vagrant:> ~# apt install g++
```

Outside of Vagrant, deploy with Capistrano:
```bash
<home:> .../slackbot-pingity-sinatra$ cap vagrant deploy
```
(Or, to deploy from a specific branch:)
```bash
<home:> .../slackbot-pingity-sinatra$ BRANCH=<branch name> cap vagrant deploy
```

Copy the systemd PingityBot service unit into system unit directory, enable, and start it:
```bash
<vagrant:> /app/pingitybot/current# cp pingitybot.service /lib/systemd/system
<vagrant:> /app/pingitybot/current# systemctl enable pingitybot.service
<vagrant:> /app/pingitybot/current# systemctl start pingitybot.service
```

... Connecting via the Slack Marketplace

... Populating the `.env` file


