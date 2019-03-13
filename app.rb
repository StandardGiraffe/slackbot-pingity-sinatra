require 'bundler/setup'

require 'sinatra/base'
require 'slack-ruby-client'

require './pingity_bot'
require './lib/verification-helpers'

class API < Sinatra::Base
  post '/command' do
    verify_token(params['token'])

    # # This should verify the request, but the request object can't be parsed.  Argh.
    # slack_request = Slack::Events::Request.new(request)
    # slack_request.verify!

    # Route the received command
    case params['command']
    when '/ping'
      uri = params['text'].split.first
      PingityBot.ping(request_data: params, uri: uri)
    else
      send_message(team_id: params['team_id'], channel: params['channel'], text: "Received an unknown command: #{params['command']}")
    end

    status 200
  end

  post '/actions' do
    verify_token(params['token'])

    payload = params['payload']

    status 200
  end
end
