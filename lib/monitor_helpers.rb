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
    total_pings = @status_results.values.sum
    passes = @status_results["PASS"]
    warnings = @status_results["WARNING(S)"]
    fail_criticals = @status_results["FAIL"]

    text = @errored_out ? "*Warning: <https://pingity.com|Pingity> resource monitoring for #{@uri} ended with an error.*".upcase : "*<https://pingity.com|Pingity> resource monitoring for #{@uri} has finished:*"

    color = if @errored_out
      "#000000"
    else
      @status_changes > 0 ? "#faaf42" : "#6495ed"
    end

    overall_report_message = @status_changes > 0 ? "*Status changed #{@status_changes} #{"time".pluralize(@status_changes)} during the monitoring period*" : "*Status did not change during the monitoring period*"
    start_and_finish_statistics = "*Initial Status:* #{@initial_report[:status]}\n*Final Status:* #{@latest_report[:status]}"
    results_statistics = "*Results Statistics (Status / Total Pings):* \n*PASS:* #{passes} / #{total_pings}   (#{status_percentage(passes)}%)\n*WARNING(S):* #{warnings} / #{total_pings}   (#{status_percentage(warnings)}%)\n*FAIL:* #{fail_criticals} / #{total_pings}   (#{status_percentage(fail_criticals)}%)"

    conclusion_text = "#{overall_report_message}\n\n#{start_and_finish_statistics}\n\n#{results_statistics}"

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

  def status_percentage(results_for_given_status)
    ((results_for_given_status.to_f / @status_results.values.sum.to_f) * 10000).round / 100.0
  end

  extend self
end
