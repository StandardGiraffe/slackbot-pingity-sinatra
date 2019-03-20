def monitor_header_blocks(uri:, endtime:)
  [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*<https://pingity.com|Pingty> is monitoring \"#{uri}\" until #{human_readable_time(endtime)} *"
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
