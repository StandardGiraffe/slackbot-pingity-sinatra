require 'pingity'

module PingityBot
  def self.ping(request_data:, uri:)
    PingityBot::Operation::Ping.new(request_data, uri: uri)
  end

  def self.refresh_ping(payload:)
    PingityBot::Operation::RefreshPing.new(payload)
  end

  def self.monitor(request_data:, uri:, monitoring_period:)
    team_id = request_data['team_id']
    user_id = request_data['user_id']
    endtime = Time.now.to_i + (monitoring_period * 60)

    ts = send_dm(
      team_id: team_id,
      user_id: user_id,
      text: monitor_header_text(uri: uri, monitoring_period: monitoring_period),
      blocks: monitor_header_blocks(uri: uri, endtime: endtime)
    )['ts']

    initial_report = self.report_on_uri(uri)

    dm_data = { team_id: team_id, user_id: user_id, ts: ts }

    # Updates the header with the canonized URI
    send_dm(
      dm_data.merge(
        text: monitor_header_text(uri: initial_report[:target], monitoring_period: monitoring_period),
        blocks: monitor_header_blocks(uri: initial_report[:target], endtime: endtime)
      )
    )

    # Conduct the actual monitoring period, capturing the final report and the number of times the status changed during that period
    final_report, status_changes = self.begin_monitoring(endtime: endtime, report: initial_report, dm_data: dm_data)
    dm_data.delete(:ts)

    send_dm(
      dm_data.merge(
        monitor_conclusion_content(
          initial_report: initial_report,
          final_report: final_report,
          status_changes: status_changes
        )
      )
    )
  end

private

  #
  # Conducts a Pingity report on a given uri
  #
  # @param [String] uri The URI to be reported on.  Pingity will attempt to canonize the resource.
  #
  # @return [Hash] A hash containing the :raw report, overall :status, canonized URI as a :target, :timestamp of the report, and :decorators hash.
  #
  # def self.report_on_uri(uri:, message_data:)
  #   report = Pingity::Report.new(
  #     uri,
  #     eager: true
  #   )

  #   {
  #     raw: report.result,
  #     status: human_readable_status(report.status),
  #     target: report.target,
  #     timestamp: report.timestamp.to_i,
  #     decorators: get_status_decorators(status: report.status, target: uri)
  #   }

  # rescue Pingity::CredentialsError => e
  #   puts e.message
  #   puts gem_error_message(Pingity::CredentialsError)
  #   send_message(team_id: team_id, channel_id: channel, ts: ts, text: "*Configuration Error:*\n#{gem_error_message(error)}")
  # end

  def self.begin_monitoring(endtime:, report:, dm_data:)
    initial_status = report[:status]
    current_status = initial_status
    previous_status = nil
    status_changes = 0

    monitoring_feed = {
      attachments: [
        monitor_status_attachment(
          decorators: report[:decorators],
          text: "*#{human_readable_time(report[:timestamp], true)}:* Initial status of #{report[:target]} was #{initial_status}"
        )
      ]
    }
    send_dm(dm_data.merge(monitoring_feed))

    while Time.now.to_i < endtime do
      report = self.report_on_uri(report[:target])

      if report[:status] == current_status
        # Status hasn't changed...
        monitoring_feed_addendum = monitor_status_attachment(
          decorators: report[:decorators],
          text: "*#{human_readable_time(report[:timestamp], true)}:* Current status of #{report[:target]} remains #{report[:status]}"
        )

        if report[:status] == previous_status
          # ... and is also the same as the previous status, so just the time signature should change.
          monitoring_feed[:attachments][-1] = monitoring_feed_addendum

        else
          # ... and is different from the previous status, so we need a new line.
          monitoring_feed[:attachments].push monitoring_feed_addendum

          previous_status = current_status
        end

      else
        # The status has changed and we need to hear about it.
        monitoring_feed[:attachments].push monitor_status_attachment(
          decorators: report[:decorators],
          text: "*#{human_readable_time(report[:timestamp], true)}: NOTICE:* Status of #{report[:target]} changed from #{current_status} to #{report[:status]}"
          )
          previous_status = current_status
          current_status = report[:status]
          status_changes += 1
        end

      send_dm(dm_data.merge(monitoring_feed))

      sleep 5
    end

    monitoring_feed[:attachments].push monitor_status_attachment(
      decorators: report[:decorators],
      text: "*#{human_readable_time(report[:timestamp], true)}: Monitoring has ended.*  Final status of #{report[:target]} was #{report[:status]}."
    )

    send_dm(dm_data.merge(monitoring_feed))

    [ report, status_changes ]
  end
end

require_relative './lib/pingity_bot/operation'
