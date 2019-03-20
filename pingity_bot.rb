require 'pingity'

module PingityBot
  def self.ping(request_data:, uri:)
    team_id = request_data['team_id']
    channel = request_data['channel_id']

    ts = send_message(
      team_id: team_id,
      channel: channel,
      text: "I'm attempting to ping \"#{uri}\".\nJust a moment, please...",
      blocks: pending_blocks(uri: uri),
      attachments: pending_attachments(uri: uri)
    )['ts']

    report = self.report_on_uri(uri)

    send_message(
      team_id: team_id,
      channel: channel,
      ts: ts,
      text: "Pingity tested \"#{report[:target]}\": #{report[:status]}",
      blocks: results_blocks(target: report[:target]),
      attachments: results_attachments(target: report[:target], decorators: report[:decorators], timestamp: report[:timestamp], status: report[:status])
    )
  end

  def self.refresh_result(payload:)
    uri = payload["actions"].first["value"]
    team_id = payload["team"]["id"]
    channel = payload["channel"]["id"]
    original_ts = payload["message"]["ts"]

    ts = send_message(
      team_id: team_id,
      channel: channel,
      ts: original_ts,
      text: "I'm attempting to ping \"#{uri}\".\nJust a moment, please...",
      blocks: pending_blocks(uri: uri),
      attachments: pending_attachments(uri: uri)
    )["ts"]

    report = self.report_on_uri(uri)

    send_message(
      team_id: team_id,
      channel: channel,
      ts: ts,
      text: "Pingity tested \"#{report[:target]}\": #{report[:status]}",
      blocks: results_blocks(target: report[:target]),
      attachments: results_attachments(target: report[:target], decorators: report[:decorators], timestamp: report[:timestamp], status: report[:status])
    )
  end

  def self.monitor(request_data:, uri:, monitoring_period:)
    team_id = request_data['team_id']
    user_id = request_data['user_id']
    endtime = Time.now.to_i + (monitoring_period * 60)

    text = "Pingity is attempting to monitor \"#{uri}\" for the next #{monitoring_period} #{"minute".pluralize(monitoring_period)}."
    ts = send_dm(
      team_id: team_id,
      user_id: user_id,
      text: text,
      blocks: monitor_header_blocks(uri: uri, endtime: endtime)
    )['ts']

    report = self.report_on_uri(uri)

    text = "Pingity is attempting to monitor \"#{report[:target]}\" for the next #{monitoring_period} #{"minute".pluralize(monitoring_period)}."
    dm_data = { team_id: team_id, user_id: user_id, ts: ts, text: text }

    # Updates the header with the canonized URI
    send_dm(
      team_id: team_id,
      user_id: user_id,
      text: text,
      ts: ts,
      blocks: monitor_header_blocks(uri: report[:target], endtime: endtime)
    )

    feedback = self.begin_monitoring(endtime: endtime, report: report, dm_data: dm_data)


  end

  private

  #
  # Conducts a Pingity report on a given uri
  #
  # @param [String] uri The URI to be reported on.  Pingity will attempt to canonize the resource.
  #
  # @return [Hash] A hash containing the :raw report, overall :status, canonized URI as a :target, :timestamp of the report, and :decorators hash.
  #
  def self.report_on_uri(uri)
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
  end

  def self.begin_monitoring(endtime:, report:, dm_data:)
    initial_status = report[:status]
    monitoring_feed = {
      attachments: monitor_status_attachment(
        decorators: report[:decorators],
        text: "Initial status of #{report[:target]} was #{initial_status} at #{human_readable_time(report[:timestamp])}"
      )
    }
    dm = dm_data.merge(monitoring_feed)

    send_dm(dm)

    while Time.now.to_i < endtime do
      sleep 5


    end
  end
end
