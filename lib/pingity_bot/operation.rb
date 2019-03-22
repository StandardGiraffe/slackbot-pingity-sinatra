require_relative '../message_helpers'

class PingityBot::Operation
  include MessageHelpers

  attr_reader :state
  attr_reader :thread

  def self.states
    @states ||= [ ]
  end

  def self.state(name)
    self.states << name
    define_method(:"state_#{name}") do
      instance_eval(&Proc.new)
    end
  end

  def initialize(payload, **options)
    @team_id = options[:team_id] || payload['team_id'] || payload.dig("team", "id")
    @user_id = options[:user_id] || payload['user_id']
    @channel_id = options[:channel_id] || payload['channel_id'] || payload.dig("channel", "id")
    @uri = options[:uri] || payload.dig("actions", 0, "value")
    @original_ts = options[:original_ts] || payload.dig("message", "ts")

    @next_state = self.class.states.first

    @thread = Thread.new do
      while @state = @next_state
        @next_state = nil
        send(:"state_#{@state}")
      end

      @state = :finished
    end
  end

  def change_to_state!(state)
    @next_state = state
  end

  def join
    @thread&.join
  end

protected
  def in_background
    Thread.new do
      yield
    end
  end

  #
  # Conducts a Pingity report on a given uri
  #
  # @param [String] uri The URI to be reported on.  Pingity will attempt to canonize the resource.
  #
  # @return [Hash] A hash containing the :raw report, overall :status, canonized URI as a :target, :timestamp of the report, and :decorators hash.
  #
  def report_on_uri(uri, **args)
    report = Pingity::Report.new(
      uri,
      eager: true
    )

    {
      raw: report.result,
      status: human_readable_status(report.status),
      target: report.target,
      timestamp: report.timestamp.to_i,
      decorators: get_status_decorators(status: report.status, target: uri)
    }

  rescue Pingity::CredentialsError, Pingity::ServiceUnreachableError, Pingity::InternalServerError, Pingity::UnexpectedResponseContentError, Pingity::NoStatusCodeGivenError => e
    puts e.message
    puts error_text(e)
    send_error(error: e)

    :failure
  end
end

require_relative './operation/ping'
require_relative './operation/refresh_ping'
require_relative './operation/monitor'
