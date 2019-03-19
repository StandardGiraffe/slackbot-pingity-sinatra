require 'bundler/setup'

require 'sinatra/base'
require 'thin'
require 'slack-ruby-client'

require './pingity_bot'
require './lib/verification-helpers'
require './lib/message-helpers'

class API < Sinatra::Base

  # The minimum and maximum number of minutes to monitor a given URI
  MONITORING_PERIOD_CLAMP = [ 5, 60 ]

  attr_reader :threads

  def initialize(app = nil, &block)
    super(app, &block)

    # Retires old threads
    @threads = Queue.new
    Thread.new do
      while thread = @threads.pop
        puts "Threadkiller is inhuming #{thread.inspect}"
        thread.join
      end
    end
  end

  # Run the encapsulated code in a thread and retire the thread when execution is finished.
  def in_background
    Thread.new do
      yield
      @threads << Thread.current
    end
  end

  configure do
    set :server, :thin
  end

  get '/debug' do
    [200, { }, JSON.dump(number_of_threads: Thread.list.size, teams: $teams)]
  end

  post '/command' do
    # Token verification is depricated.  Use #verify_signature instead if possible.
    # verify_token(params['token'])
    verify_signature

    in_background do
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
        uri = params['text'].split.first
        monitoring_period = params['text'].split.second.to_i.clamp(MONITORING_PERIOD_CLAMP[0], MONITORING_PERIOD_CLAMP[1])

        if uri == nil
          send_error(params: params, error: :monitor_command_missing_uri)
        elsif uri.include?("@")
          send_error(params: params, error: :monitor_command_email_disallowed)
        else
          PingityBot.monitor(request_data: params, uri: uri, monitoring_period: monitoring_period)
        end

      else
        send_message(team_id: params['team_id'], channel: params['channel_id'], text: "Received an unknown command: #{params['command']}")
      end
    end

    200
  end

  post '/actions' do
    payload = JSON.parse(params['payload'])

    # Token verification is depircated.  Use #verify_signature instead if possible.
    # verify_token(payload['token'])
    verify_signature

    in_background do
      p payload['actions']
      action = payload['actions'].first['action_id']
      puts action

      case action
      when 'refresh_result'
        PingityBot.refresh_result(payload: payload)
      when 'redirect_to_pingity'
        puts "Redirected a user to the Pingity website."
      else
        puts "WARNING: WEIRD ACTION PAYLOAD RECEIVED.  REJECTED: #{action}"
        halt 404, "WARNING: WEIRD ACTION PAYLOAD RECEIVED.  REJECTED: #{action}"
      end
    end

    200
  end
end
