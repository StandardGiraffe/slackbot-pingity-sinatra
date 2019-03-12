#
# Posts or updates a bot message via Slack's Web API.  Will automatically update rather than post if a timestamp (ts) is included.
#
# @param [String] team_id Slack's ID for the Team/Workspace to send the message to
# @param [String] channel Slack's ID for the channel where the request was made
# @param [Float] ts (Optional) Timestamp of the bot's previous message.  If included, the specified message will be updated, rather than a new message posted.
# @param [String] text (optional) Simple message.  If a blocks argument is also provided, text will not be printed (but may be displayed on notifications), and should be non-critical.
# @param [Array] blocks (optional) Array of one or more message blocks (hashes).  If included, the text param will not be shown on the Slack channel (but may be displayed on notifications).
# @param [Array] attachments (optional) Array of one or more message attachments (hashes).
#
# @return [Hash] API response
#
def send_message(team_id:, channel:, ts: nil, text: nil, blocks: nil, attachments: nil)
  message = {
    as_user: 'true',
    channel: channel,
    unfurl_media: false
  }

  if text
    message.merge!({ text: text })
  end

  if blocks
    message.merge!({ blocks: blocks })
  end

  if attachments
    message.merge!({ attachments: attachments })
  end

  if ts
    message.merge!({ ts: ts })
    response = $teams[team_id]['client'].chat_update(message)
  else
    response = $teams[team_id]['client'].chat_postMessage(message)
  end

  response
end

#
# Returns status image and alt-text for a tested resource.
#
# @param [String] status Accepts 'pass', 'warning', and 'fail_critical'
# @param [String] target The target URI of the Pingity test
#
# @return [Hash] Returns a hash with :url and :alt_text for inclusion in a message block image and :color for attachment colouring.
#
def get_status_decorators(status:, target:)
  case status
  when "pass"
    {
      url: "https://www.tutorialspoint.com/ruby/images/ruby-mini-logo.jpg",
      alt_text: "#{target} is passing",
      color: "#8cc54b"
    }
  when "warning"
    {
      url: "https://www.tutorialspoint.com/ruby/images/ruby-mini-logo.jpg",
      alt_text: "#{target} is raising warnings",
      color: "#faaf42"
    }
  when "fail_critical"
    {
      url: "https://www.tutorialspoint.com/ruby/images/ruby-mini-logo.jpg",
      alt_text: "#{target} is failing",
      color: "#cf4b3f"
    }
  else
    {
      url: "https://www.tutorialspoint.com/ruby/images/ruby-mini-logo.jpg",
      alt_text: "#{target} is inconclusive for some reason...",
      color: "#b0b0a6"
    }
  end
end

# Converts a pingity status code to a human-readable equivalent.
def human_readable_status(status)
  {
    "pass" => "PASS",
    "warning" => "WARNING(S)",
    "fail_critical" => "FAIL"
  }[status]
end
