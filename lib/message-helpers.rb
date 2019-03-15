#
# Posts or updates a bot message via Slack's Web API.  Will automatically update rather than post if a timestamp (ts) is included.
#
# @param [String] team_id Slack's ID for the Team/Workspace to send the message to
# @param [String] channel Slack's ID for the channel where the request was made
# @param [Float] ts (Optional) Timestamp of the bot's previous message.  If included, the specified message will be updated, rather than a new message posted.
# @param [String] text (optional) Simple message.  If a blocks argument is also provided, text will not be printed (but may be displayed on notifications), and should be non-critical.
# @param [Array] blocks (optional) Array of one or more message blocks (hashes).  If included, the text param will not be shown on the Slack channel (but may be displayed on notifications).
# @param [Array] attachments (optional) Array of one or more message attachments (hashes).
# @param [String] user (optional) User ID.  If included, the specified message will be sent as an ephemeral message only to the specified user.
#
# @return [Hash] API response
#
def send_message(team_id:, channel:, ts: nil, text: nil, blocks: nil, attachments: nil, user: nil)
  message = {
    as_user: 'true',
    channel: channel,
    unfurl_media: false,
    mrkdwn: true
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
  elsif user
    message.merge!({ user: user })
    response = $teams[team_id]['client'].chat_postEphemeral(message)
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
      url: "https://raw.githubusercontent.com/StandardGiraffe/slackbot-pingity-sinatra/master/bin/badges/pingity-badge-passing.png",
      alt_text: "#{target} is passing",
      color: "#8cc54b"
    }
  when "warning"
    {
      url: "https://raw.githubusercontent.com/StandardGiraffe/slackbot-pingity-sinatra/master/bin/badges/pingity-badge-warning.png",
      alt_text: "#{target} is raising warnings",
      color: "#faaf42"
    }
  when "fail_critical"
    {
      url: "https://raw.githubusercontent.com/StandardGiraffe/slackbot-pingity-sinatra/master/bin/badges/pingity-badge-failing.png",
      alt_text: "#{target} is failing",
      color: "#cf4b3f"
    }
  else
    {
      url: "https://raw.githubusercontent.com/StandardGiraffe/slackbot-pingity-sinatra/master/bin/badges/pingity-badge-failing.png",
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

def pending_blocks(uri:)
  [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*<https://pingity.com|Pingty> is trying to test \"#{uri}\"...*"
      }
    }
  ]
end

def pending_attachments(uri:)
  [
    {
      "color": "#6495ed",
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*Overall Status:*\nPENDING\n*Current as of:*\n..."
          },
          "accessory": {
            "type": "image",
            "image_url": "https://raw.githubusercontent.com/StandardGiraffe/slackbot-pingity-sinatra/master/bin/badges/pingity-badge-pending.png",
            "alt_text": "#{uri} is being tested..."
          }
        },
        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "emoji": true,
                "text": "Or, try it on Pingity.com"
              },
              "url": ENV['PINGITY_API_BASE']
            }
          ]
        }
      ]
    }
  ]
end

def results_blocks(target:)
  [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*<https://pingity.com|Pingty> results for #{target}: *"
      }
    }
  ]
end

def results_attachments(target:, decorators:, timestamp:, status:)
  [
    {
      "color": decorators[:color],
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*Overall Status:*\n#{status}\n*Current as of:*\n<!date^#{timestamp}^{date_short_pretty} at {time}|Timestamp unavailable, sorry.>"
          },
          "accessory": {
            "type": "image",
            "image_url": decorators[:url],
            "alt_text": decorators[:alt_text]
          }
        },
        {
          "type": "actions",
          "elements": [
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "emoji": true,
                "text": "Details on Pingity.com"
              },
              "url": "#{ENV['PINGITY_API_BASE']}?target=#{target}"
            },
            {
              "type": "button",
              "text": {
                "type": "plain_text",
                "emoji": true,
                "text": "Refresh Result"
              },
              "value": target,
              "action_id": "refresh_result"
            }
          ]
        }
      ]
    },
  ]
end

def send_error(params:, error:)
  send_message(
    team_id: params['team_id'],
    channel: params['channel_id'],
    user: params['user_id'],
    text: "Error: #{error.to_s}",
    blocks: error_blocks(error)
  )
end

def error_blocks(error)
  { ping_command_missing_argument: [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*Argument Missing: * `/ping` requires a URI (eg. `/ping example.com`)"
        }
      }
    ],

    monitor_command_missing_uri: [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*Argument Missing: * `/monitor` requires a web address (eg. `/monitor example.com 10`)"
        }
      }
    ],

    monitor_command_email_disallowed: [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*Argument Invalid: * Email addresses are not available for `/monitor`ing at this time.  Sorry!"
        }
      }
    ],

    monitor_command_missing_period: [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*Argument Missing: * `/monitor` requires a number of minutes to monitor the web address (eg. `/monitor example.com 10`)"
        }
      }
    ]
  }[error]
end
