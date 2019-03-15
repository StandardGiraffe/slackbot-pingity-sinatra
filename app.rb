require 'bundler/setup'

require 'sinatra/base'
require 'slack-ruby-client'

require './pingity_bot'
require './lib/verification-helpers'
require './lib/message-helpers'

class API < Sinatra::Base
  post '/command' do
    # Token verification is depricated.  Use #verify_signature instead if possible.
    # verify_token(params['token'])
    verify_signature

    # Route the received command
    case params['command']
    when '/ping'
      uri = params['text'].split.first

      unless uri
        send_error(params: params, error: :ping_command_missing_argument)
      else
        PingityBot.ping(request_data: params, uri: uri)
      end

    when '/monitor'
      puts "Hey!  I got a /monitor request!  Neat!"
      puts params['user_id']

      uri = params['text'].split.first
      monitoring_period = params['text'].split.second.to_i

      if uri == nil
        send_error(params: params, error: :monitor_command_missing_uri)
      elsif uri.include?("@")
        send_error(params: params, error: :monitor_command_email_disallowed)
      elsif monitoring_period == 0
        send_error(params: params, error: :monitor_command_missing_period)
      else
        PingityBot.monitor(request_data: params, uri: uri, monitoring_period: monitoring_period)
      end

    else
      send_message(team_id: params['team_id'], channel: params['channel_id'], text: "Received an unknown command: #{params['command']}")
    end

    200
  end

  post '/actions' do
    payload = JSON.parse(params['payload'])
    puts payload.to_json

    # Token verification is depircated.  Use #verify_signature instead if possible.
    # verify_token(payload['token'])
    verify_signature

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
