require 'bundler/setup'

require 'sinatra/base'
require 'slack-ruby-client'

require './pingity_bot'
require './lib/verification-helpers'
require './lib/message-helpers'

class API < Sinatra::Base
  post '/command' do
    verify_token(params['token'])

    # Route the received command
    case params['command']
    when '/ping'
      uri = params['text'].split.first

      unless uri
        send_error(params: params, error: :ping_command_missing_argument)
      else
        PingityBot.ping(request_data: params, uri: uri)
      end

    else
      send_message(team_id: params['team_id'], channel: params['channel_id'], text: "Received an unknown command: #{params['command']}")
    end

    200
  end

  post '/actions' do
    payload = JSON.parse(params['payload'])
    puts payload.to_json

    verify_token(payload['token'])

    action = payload['actions'].first['action_id']

    case
    when 'refresh_result'
      PingityBot.refresh_result(payload: payload)
    else
      puts "WARNING: WEIRD ACTION PAYLOAD RECEIVED.  REJECTED."
      halt 404, "WARNING: WEIRD ACTION PAYLOAD RECEIVED.  REJECTED: #{action}"
    end

    200
  end
end
