class PingityBot::Operation::Ping < PingityBot::Operation
  state(:sending_initial_notification) do
    @ts = send_message(
      team_id: @team_id,
      channel: @channel_id,
      text: "I'm attempting to ping \"#{@uri}\".\nJust a moment, please...",
      blocks: pending_blocks(uri: @uri),
      attachments: pending_attachments(uri: @uri)
    )['ts']

    change_to_state!(:reporting_on_uri)
  end

  state(:reporting_on_uri) do
    @report = self.report_on_uri(@uri)

    change_to_state!(:sending_final_notification)
  end

  state(:sending_final_notification) do
    send_message(
      team_id: @team_id,
      channel: @channel_id,
      ts: @ts,
      text: "Pingity tested \"#{@report[:target]}\": #{@report[:status]}",
      blocks: results_blocks(target: @report[:target]),
      attachments: results_attachments(
        target: @report[:target],
        decorators: @report[:decorators],
        timestamp: @report[:timestamp],
        status: @report[:status]
      )
    )
  end
end
