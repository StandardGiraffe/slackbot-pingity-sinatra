module PingHelpers
  def pending_blocks(uri:)
    [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*<https://pingity.com|Pingity> is trying to test \"#{uri}\"...*"
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
                "url": ENV['PINGITY_API_BASE'],
                "action_id": "redirect_to_pingity"
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
          "text": "*<https://pingity.com|Pingity> results for #{target}: *"
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
              "text": "*Overall Status:*\n#{status}\n*Current as of:*\n#{human_readable_time(timestamp)}"
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
                "url": "#{ENV['PINGITY_API_BASE']}?target=#{target}",
                "action_id": "redirect_to_pingity"
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

  extend self
end
