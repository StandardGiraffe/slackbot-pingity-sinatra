require 'bundler/setup'

require 'sinatra/base'
require 'slack-ruby-client'

require './pingity_bot'

class API < Sinatra::Base
  post '/command' do
    # Inform Slack that the slash command has been received
    status 200

    unless SLACK_CONFIG[:slack_verification_token] == params['token']
      halt 403, "Invalid Slack verification token received: #{params['token']}"
    end

    # Route the received command
    case params['command']
    when '/ping'
      uri = params['text'].split.first
      PingityBot.ping(request_data: params, uri: uri)
    else
      send_message(team_id: params['team_id'], channel: params['channel'], text: "Received an unknown command: #{params['command']}")
    end
  end
end
