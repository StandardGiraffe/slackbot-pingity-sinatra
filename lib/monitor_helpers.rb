module MonitorHelpers
  def monitor_header_blocks
    [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*<https://pingity.com|Pingity> is monitoring \"#{@uri}\" until #{human_readable_time(@endtime)} *"
        }
      }
    ]
  end

  #
  # Creates a monitoring status update block with the given text, timestamp, and decorator colour
  #
  # @param [String] text Markdown-formatted text for the attachment block
  # @param [Hash] decorators (optional) Decorators hash containing the appropriate colour for the report; defaults to black
  #
  # @return [Hash] Returns a status update attachment.
  #
  def monitor_status_attachment(text:, color:)
    {
      "color": color,
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": text
          }
        }
      ]
    }
  end

  def monitor_header_text
    "Pingity is attempting to monitor \"#{@uri}\" for the next #{@monitoring_period} #{"minute".pluralize(@monitoring_period)}."
  end

  def monitor_conclusion_content
    text = @errored_out ? "*Warning: <https://pingity.com|Pingity> resource monitoring for #{@uri} ended with an error.*".upcase : "*<https://pingity.com|Pingity> resource monitoring for #{@uri} has finished:*"

    color = if @errored_out
      "#000000"
    else
      @status_changes ? "#6495ed" : "#faaf42"
    end

    conclusion_text = if @status_changes > 0
      "*Status changed #{@status_changes} #{"time".pluralize(@status_changes)} during the monitoring period* \n\n*Initial Status:* #{@initial_report[:status]}\n*Final Status:* #{@latest_report[:status]}\n\nPlease see the above log for details."
    else
      "*Status did not change during the monitoring period*\n\n*Initial Status:* #{@initial_report[:status]}\n*Final Status:* #{@latest_report[:status]}"
    end

    {
      text: text,
      blocks: [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": text
          }
        }
      ],
      attachments: [
        {
          color: color,
          blocks: [
            type: "section",
            text: {
              type: "mrkdwn",
              text: conclusion_text
            }
          ]
        }
      ]
    }
  end

  extend self
end
