require 'sinatra/base'
require 'thin'
require 'slack-ruby-client'

require_relative './pingity_bot'
require_relative './lib/verification_helpers'
require_relative './lib/message_helpers'
# require './lib/ping-helpers'
# require './lib/monitor-helpers'

class API < Sinatra::Base
  include VerificationHelpers
  include MessageHelpers

  # The minimum and maximum number of minutes to monitor a given URI
  MONITORING_PERIOD_CLAMP = [ 1, 60 ]

  attr_reader :threads

  def initialize(app = nil, &block)
    super(app, &block)

    # Retires old threads
    @threads = Queue.new
    Thread.new do
      while thread = @threads.pop
        puts "Threadkiller is inhuming #{thread.inspect}; #{Thread.list.size - 1} #{"thread".pluralize(Thread.list.size - 1)} left."
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

  get '/bot/debug' do
    [200, { }, JSON.dump(number_of_threads: Thread.list.size, teams: $teams)]
  end

  post '/bot/command' do
    in_background do
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
        uri = params['text'].split.first
        monitoring_period = params['text'].split.second.to_i.clamp(MONITORING_PERIOD_CLAMP[0], MONITORING_PERIOD_CLAMP[1])

        case uri
        when nil, /\A\s*\z/
          send_error(params: params, error: :monitor_command_missing_uri)
        when /@/
          send_error(params: params, error: :monitor_command_email_disallowed)
        else
          PingityBot.monitor(request_data: params, uri: uri, monitoring_period: monitoring_period)
        end

      else
        send_message(team_id: params['team_id'], channel_id: params['channel_id'], text: "Received an unknown command: #{params['command']}")
      end
    end

    200
  end

  post '/bot/actions' do
    payload = JSON.parse(params['payload'])

    in_background do
      # Token verification is depircated.  Use #verify_signature instead if possible.
      # verify_token(payload['token'])
      verify_signature

      p payload['actions']
      action = payload['actions'].first['action_id']
      puts action

      case action
      when 'refresh_result'
        PingityBot.refresh_ping(payload: payload)
      when 'redirect_to_pingity'
        puts "Redirected a user to the Pingity website."
      else
        puts "**********"
        puts "WARNING: WEIRD ACTION PAYLOAD RECEIVED.  REJECTED: #{action}"
        puts "\nPayload:"
        p payload
        puts "**********"
        # halt 404, "WARNING: WEIRD ACTION PAYLOAD RECEIVED.  REJECTED: #{action}"
      end
    end

    200
  end
end
