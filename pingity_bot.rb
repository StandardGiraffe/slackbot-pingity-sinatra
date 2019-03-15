require 'pingity'

class PingityBot
  def self.ping(request_data:, uri:)
    team_id = request_data['team_id']
    channel = request_data['channel_id']

    initial_check = send_message(
      team_id: team_id,
      channel: channel,
      text: "I'm attempting to ping \"#{uri}\".\nJust a moment, please...",
      blocks: pending_blocks(uri: uri),
      attachments: pending_attachments(uri: uri)
    )

    report = Pingity::Report.new(
      uri,
      eager: true
    )

    status = human_readable_status(report.status)
    target = report.target
    timestamp = report.timestamp.to_i
    decorators = get_status_decorators(status: report.status, target: target)

    send_message(
      team_id: team_id,
      channel: channel,
      ts: initial_check['ts'],
      text: "Pingity tested \"#{target}\": #{status}",
      blocks: results_blocks(target: target),
      attachments: results_attachments(target: target, decorators: decorators, timestamp: timestamp, status: status)
    )
  end

  def self.refresh_result(payload:)
    uri = payload["actions"].first["value"]
    team_id = payload["team"]["id"]
    channel = payload["channel"]["id"]
    original_ts = payload["message"]["ts"]

    initial_check = send_message(
      team_id: team_id,
      channel: channel,
      ts: original_ts,
      text: "I'm attempting to ping \"#{uri}\".\nJust a moment, please...",
      blocks: pending_blocks(uri: uri),
      attachments: pending_attachments(uri: uri)
    )

    report = Pingity::Report.new(
      uri,
      eager: true
    )

    status = human_readable_status(report.status)
    target = report.target
    timestamp = report.timestamp.to_i
    decorators = get_status_decorators(status: report.status, target: target)

    send_message(
      team_id: team_id,
      channel: channel,
      ts: initial_check['ts'],
      text: "Pingity tested \"#{target}\": #{status}",
      blocks: results_blocks(target: target),
      attachments: results_attachments(target: target, decorators: decorators, timestamp: timestamp, status: status)
    )
  end

  def self.monitor(request_data:, uri:, monitoring_period:)
    team_id = request_data['team_id']
    user_id = request_data['user_id']
    text = "Hey, the URI I received is \"#{uri}\" and the monitoring period is #{monitoring_period} #{"minute".pluralize(monitoring_period)}!  Hope that's okay."
    send_dm(team_id: team_id, user_id: user_id, text: text)
  end
end
