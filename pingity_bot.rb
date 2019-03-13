require 'pingity'
require './lib/message-helpers'

class PingityBot
  def self.ping(request_data:, uri:)
    team_id = request_data['team_id']
    channel = request_data['channel_id']

    initial_check = send_message(
      team_id: team_id,
      channel: channel,
      text: "I'm attempting to ping \"#{uri}\".\nJust a moment, please...",
      blocks: [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*<https://pingity.com|Pingty> is trying to test \"#{uri}*\""
          }
        }
      ],
      attachments: [
        {
          "color": "#6495ed",
          "blocks": [
            {
              "type": "section",
              "text": {
                "type": "mrkdwn",
                "text": "*Overall Status:*\nPENDING*\n*Current as of:*\n..."
              },
              "accessory": {
                "type": "image",
                "image_url": "https://www.tutorialspoint.com/ruby/images/ruby-mini-logo.jpg",
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
                  "url": "https://pingity.com/"
                },
                {
                  "type": "button",
                  "text": {
                    "type": "plain_text",
                    "emoji": true,
                    "text": "Refresh Result"
                  },
                  "value": "retest"
                }
              ]
            }
          ]
        }
      ]
    )

    report = Pingity::Report.new(
      uri,
      eager: true
    )

    status = human_readable_status(report.status)
    target = report.target
    timestamp = report.timestamp.to_i
    decorators = get_status_decorators(status: report.status, target: target)

    send_message(
      team_id: team_id,
      channel: channel,
      ts: initial_check['ts'],
      text: "Pingity tested \"#{target}\": #{status}",
      blocks: [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*<https://pingity.com|Pingty> has your results for #{target}*"
          }
        }
      ],
      attachments: [
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
                  "url": "https://pingity.com/?target=#{target}"
                },
                {
                  "type": "button",
                  "text": {
                    "type": "plain_text",
                    "emoji": true,
                    "text": "Refresh Result"
                  },
                  "value": "retest"
                }
              ]
            }
          ]
        },
      ]
    )
  end
end
