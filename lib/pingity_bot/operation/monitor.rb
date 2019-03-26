require_relative '../../monitor_helpers'

class PingityBot::Operation::Monitor < PingityBot::Operation
  include MonitorHelpers

  state(:monitor_notify_initial_request_received) do
    @endtime = Time.now.to_i + (@monitoring_period * 60)

    @ts = send_dm(
      text: monitor_header_text,
      blocks: monitor_header_blocks
    )['ts']

    change_to_state!(:monitor_reporting_initially_on_uri)
  end

  state(:monitor_reporting_initially_on_uri) do
    @initial_report = self.report_on_uri(@uri)

    if @initial_report[:status] == "ERROR"
      delete_last_message!
    else
      change_to_state!(:monitor_updating_header_with_canonized_uri)
    end
  end

  # Updates the header with the canonized URI
  state(:monitor_updating_header_with_canonized_uri) do
    # Updates @uri with the Pingity-canonized value for use hereafter
    @uri = @initial_report[:target]

    send_dm(
      text: monitor_header_text,
      blocks: monitor_header_blocks,
      ts: @ts,
      update: true
    )

    change_to_state!(:monitor_building_bulletin_variables)
  end

  state(:monitor_building_bulletin_variables) do
    @initial_status = @current_status = @initial_report[:status]
    @previous_status = nil

    @status_changes = 0
    @status_results = {
      "PASS" => 0,
      "WARNING(S)" => 0,
      "FAIL" => 0
    }

    change_to_state!(:monitor_posting_initial_feed_bulletin)
  end

  state(:monitor_posting_initial_feed_bulletin) do
    @monitoring_feed = [
      monitor_status_attachment(
        color: @initial_report[:decorators][:color],
        text: "*#{human_readable_time(@initial_report[:timestamp], true)}:* Initial status of #{@initial_report[:target]} was #{@initial_status}"
      )
    ]

    increment_results(@initial_report[:status])
    post_monitoring_bulletin!

    change_to_state!(:monitor_updating_feed_bulletins)
  end

  # Conduct the actual monitoring period, capturing the final report and the number of times the status changed during that period
  state(:monitor_updating_feed_bulletins) do
    @latest_report = self.report_on_uri(@uri)

    case @latest_report[:status]
    when "ERROR"
      @errored_out = true
      @monitoring_feed.push(
        monitor_status_attachment(
          text: "*ERROR:* An error occurred while monitoring.  Please review PingityBot's logs for more information.",
          color: "#000000"
        )
      )

      post_monitoring_bulletin!

      change_to_state!(:monitor_posting_conclusions)

    when @current_status
      # Status hasn't changed...
      monitoring_feed_addendum = monitor_status_attachment(
        color: @latest_report[:decorators][:color],
        text: "*#{human_readable_time(@latest_report[:timestamp], true)}:* Current status of #{@latest_report[:target]} remains #{@latest_report[:status]}"
      )

      if @latest_report[:status] == @previous_status
        # ... and is also the same as the previous status, so just the time signature should change.
        @monitoring_feed[-1] = monitoring_feed_addendum

      else
        # ... and is different from the previous status, so we need a new line.
        @monitoring_feed.push(monitoring_feed_addendum)

        @previous_status = @current_status
      end

    else
      # The status has changed and we need to hear about it.
      @monitoring_feed.push(
        monitor_status_attachment(
          color: @latest_report[:decorators][:color],
          text: "*#{human_readable_time(@latest_report[:timestamp], true)}: NOTICE:* Status of #{@latest_report[:target]} changed from #{@current_status} to #{@latest_report[:status]}"
        )
      )

      @previous_status = @current_status
      @current_status = @latest_report[:status]
      @status_changes += 1
    end

    increment_results(@latest_report[:status])
    post_monitoring_bulletin!

    sleep 5

    if Time.now.to_i < @endtime
      change_to_state!(:monitor_updating_feed_bulletins)
    else
      @monitoring_feed.push(
        monitor_status_attachment(
          color: @latest_report[:decorators][:color],
          text: "*#{human_readable_time(@latest_report[:timestamp], true)}: Monitoring has ended.*\nFinal status of #{@latest_report[:target]} was #{@latest_report[:status]}."
        )
      )

      post_monitoring_bulletin!

      change_to_state!(:monitor_posting_conclusions)
    end
  end

  state(:monitor_posting_conclusions) do
    send_dm(monitor_conclusion_content)
  end

  state(:monitor_posting_conclusions_error) do
    send_dm(monitor_conclusion_error_content)
  end

protected
  def post_monitoring_bulletin!
    send_dm(
      text: monitor_header_text,
      blocks: monitor_header_blocks,
      update: true,
      ts: @ts,
      attachments: @monitoring_feed
    )
  end

  def increment_results(status)
    @status_results[status] += 1
  end
end
