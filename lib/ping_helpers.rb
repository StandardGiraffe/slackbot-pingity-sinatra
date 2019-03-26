module PingHelpers
  def pending_blocks
    [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*<https://pingity.com|Pingity> is trying to test \"#{@uri}\"...*"
        }
      }
    ]
  end

  def pending_attachments
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
              "alt_text": "#{@uri} is being tested..."
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

  def results_blocks
    [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*<https://pingity.com|Pingity> results for #{@uri}: *"
        }
      }
    ]
  end

  def results_attachments
    [
      {
        "color": @report[:decorators][:color],
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Overall Status:*\n#{@report[:status]}\n*Current as of:*\n#{human_readable_time(@report[:timestamp])}"
            },
            "accessory": {
              "type": "image",
              "image_url": @report[:decorators][:url],
              "alt_text": @report[:decorators][:alt_text]
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
                "url": "#{ENV['PINGITY_API_BASE']}?target=#{@uri}",
                "action_id": "redirect_to_pingity"
              },
              {
                "type": "button",
                "text": {
                  "type": "plain_text",
                  "emoji": true,
                  "text": "Refresh Result"
                },
                "value": @uri,
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
