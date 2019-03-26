require_relative '../../ping_helpers'

class PingityBot::Operation::RefreshPing < PingityBot::Operation
  include PingHelpers

  state(:refresh_ping_sending_initial_notification) do
    @ts = send_message(
      ts: @original_ts,
      update: true,
      text: "I'm attempting to ping \"#{@uri}\".\nJust a moment, please...",
      blocks: pending_blocks,
      attachments: pending_attachments
    )["ts"]

    change_to_state!(:refresh_ping_reporting_on_uri)
  end

  state(:refresh_ping_reporting_on_uri) do
    @report = self.report_on_uri(@uri)

    if @report[:status] == "ERROR"
      delete_message!(@original_ts)
    else
      # Update @uri to Pingity-canonized version
      @uri = @report[:target]

      change_to_state!(:refresh_ping_sending_final_notification)
    end
  end

  state(:refresh_ping_sending_final_notification) do
    send_message(
      update: true,
      text: "Pingity tested \"#{@uri}\": #{@report[:status]}",
      blocks: results_blocks,
      attachments: results_attachments
    )
  end
end
