module MonitorHelpers
  def monitor_header_blocks(uri:, endtime:)
    [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*<https://pingity.com|Pingity> is monitoring \"#{uri}\" until #{human_readable_time(endtime)} *"
        }
      }
    ]
  end

  #
  # Creates a monitoring status update block with the given text, timestamp, and decorator colour
  #
  # @param [String] text Markdown-formatted text for the attachment block
  # @param [Hash] decorators Decorators hash containing the appropriate colour for the report
  #
  # @return [Hash] Returns a status update attachment.
  #
  def monitor_status_attachment(text:, decorators:)
    {
      "color": decorators[:color],
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

  def monitor_header_text(uri:, monitoring_period:)
    "Pingity is attempting to monitor \"#{uri}\" for the next #{monitoring_period} #{"minute".pluralize(monitoring_period)}."
  end

  def monitor_conclusion_content(initial_report:, final_report:, status_changes:)
    text = "*<https://pingity.com|Pingity> resource monitoring for #{initial_report[:target]} has finished:*"
    color = status_changes ? "#6495ed" : "#faaf42"
    conclusion_text = if status_changes > 0
      "*Status changed #{status_changes} #{"time".pluralize(status_changes)} during the monitoring period* \n\n*Initial Status:* #{initial_report[:status]}\n*Final Status:* #{final_report[:status]}\n\nPlease see the above log for details."
    else
      "*Status did not change during the monitoring period*\n\n*Initial Status:* #{initial_report[:status]}\n*Final Status:* #{final_report[:status]}"
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
