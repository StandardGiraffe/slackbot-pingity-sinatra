require_relative '../../ping_helpers'

class PingityBot::Operation::Ping < PingityBot::Operation
  include PingHelpers

  state(:ping_sending_initial_notification) do
    @ts = send_message(
      text: "I'm attempting to ping \"#{@uri}\".\nJust a moment, please...",
      blocks: pending_blocks(uri: @uri),
      attachments: pending_attachments(uri: @uri)
    )['ts']

    change_to_state!(:ping_reporting_on_uri)
  end

  state(:ping_reporting_on_uri) do
    @report = self.report_on_uri(@uri)

    if @report == :failure
      delete_last_message!
    else
      change_to_state!(:ping_sending_final_notification)
    end
  end

  state(:ping_sending_final_notification) do
    send_message(
      update: true,
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
