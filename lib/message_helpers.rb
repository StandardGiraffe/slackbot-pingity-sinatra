module MessageHelpers

  ERROR_TEXT = {
    ping_command_missing_argument: "*Argument Missing: * `/ping` requires a URI (eg. `/ping example.com`)",
    monitor_command_missing_uri: "*Argument Missing: * `/monitor` requires a web address (eg. `/monitor example.com 10`)",
    monitor_command_email_disallowed: "*Argument Invalid: * Email addresses are not available for `/monitor`ing at this time.  Sorry!",
    Pingity::CredentialsError => "*Configuration Error:* \nPingityBot's credentials were rejected by #{ENV['PINGITY_API_BASE']}.  Ensure PingityBot's .env file contains a PINGITY_ID and PINGITY_SECRET that match your Pingity API Key's ID and Secret."
  }

  # Posts or updates a bot message via Slack's Web API.  Will automatically update rather than post if a timestamp (ts) is included.
  #
  # @param [String] team_id (optional) A specific team id to post to; defaults to the team where the request was made
  # @param [String] channel_id (optional) A specific channel id to post to; defaults to the channel where the request was made
  # @param [Float] ts (Optional) Timestamp of a previous message sent by the bot.  If included and if update: true, the post will replace the existing message at this timestamp rather than the most recent message.
  # @param [Boolean] update (Optional) If provided, the specified message will replace the post with the provided timestamp, :ts, or the most recent message posted, by default.
  # @param [String] text (optional) Simple message.  If a blocks argument is also provided, text will not be printed (but may be displayed on notifications), and should be non-critical.
  # @param [Array] blocks (optional) Array of one or more message blocks (hashes).  If included, the text param will not be shown on the Slack channel (but may be displayed on notifications).
  # @param [Array] attachments (optional) Array of one or more message attachments (hashes).
  # @param [String] user_id (optional) User ID.  If included and ephemeral: true, an ephemeral message will be sent to the specified user.
  # @param [Boolean] ephemeral (optional) If included, the specified message will be sent as an ephemeral message only to the specified user, or to the triggering user if not specified.
  #
  # @return [Hash] API response
  #
  def send_message(**args)
    message = {
      as_user: 'true',
      channel: args[:channel_id] || @channel_id,
      unfurl_media: false,
      unfurl_links: false,
      mrkdwn: true
    }

    if args[:text]
      message.merge!({ text: args[:text] })
    end

    if args[:blocks]
      message.merge!({ blocks: args[:blocks] })
    end

    if args[:attachments]
      message.merge!({ attachments: args[:attachments] })
    end

    if args[:update]
      message.merge!({ ts: args[:ts] || @ts })
      response = $teams[args[:team_id] || @team_id]['client'].chat_update(message)
    elsif args[:ephemeral]
      message.merge!({ user: args[:user_id] || @user_id })
      response = $teams[args[:team_id] || @team_id]['client'].chat_postEphemeral(message)
    else
      response = $teams[args[:team_id] || @team_id]['client'].chat_postMessage(message)
    end

    response
  end

  def delete_last_message!
    $teams[@team_id]['client'].chat_delete(
      as_user: 'true',
      channel: @channel_id,
      ts: @ts
    )
  end

  #
  # Sends a direct message to the specified user, accepting the same parameters as #send_message
  #
  # @param [String] user_id (optional) Intended recipient's Slack ID; defaults to triggering user
  # @param [String] text (optional) A simple text string to send, or the alt message if blocks are included
  # @param [Array] blocks (Optional) message blocks.  If provided, the text argument will not be shown to the user.
  # @param [Array] attachments (Optional) attachment blocks.  These will be appended to the message if provided.
  # @param [Boolean] ephemeral (optional) If included, the specified message will be sent as an ephemeral message only to the specified user, or to the triggering user if not specified.
  # @param [Boolean] update (Optional) If provided, the specified message will replace the post with the provided timestamp, :ts, or the most recent message posted, by default.
  # @param [Float] ts (Optional) Timestamp of a previous message sent by the bot.  If included and if update: true, the post will replace the existing message at this timestamp rather than the most recent message.
  #
  # @return [Obj] Response object for the message sent
  #
  def send_dm(text: nil, blocks: nil, attachments: nil, update: false)
    channel_id = $teams[@team_id]['client'].conversations_open(
      {
        users: args[:user_id] || @user_id,
        return_im: true
      }
    )['channel']['id']

    message = {
      channel_id: channel_id,
      text: args[:text],
      blocks: args[:blocks],
      attachments: args[:attachments],
      ts: args[:ts],
      update: args[:update],
      ephemeral: args[:ephemeral]
    }

    send_message(message)
  end

  # Converts a pingity status code to a human-readable equivalent.
  def human_readable_status(status)
    {
      "pass" => "PASS",
      "warning" => "WARNING(S)",
      "fail_critical" => "FAIL"
    }[status]
  end

  #
  # Outputs a Slack-parsable string intended to display the date and time nicely
  #
  # @param [Integer] timestamp Unix Epoch timestamp
  # @param [Boolean] precise (Default FALSE) If true, a more precise timestamp will be returned
  #
  # @return [String] Timestamp in human-readable format
  #
  def human_readable_time(timestamp, precise = false)
    unless precise
      "<!date^#{timestamp}^{date_short_pretty} at {time}|Timestamp unavailable, sorry.>"
    else
      "<!date^#{timestamp}^{date_num} at {time_secs}|Timestamp unavailable, sorry.>"
    end
  end

  #
  # Sends a message notification (ephemerally) to the specified or triggering user.  Can update an existing post if required.
  #
  # @param [Hash] params If the error is raised before an action is started, sending in :params[team_id], :params[channel_id], :params[user_id] will be necessary to route the message; otherwise, this information can be taken from the action automatically
  # @param [Symbol] error Error code
  #
  # @return [Hash] Slack's response object
  #
  def send_error(error:, **args)
    send_message(
      team_id: @team_id || args[:params]['team_id'],
      channel_id: @channel_id || args[:params]['channel_id'],
      user_id: @user_id || args[:params]['user_id'],
      ephemeral: true,
      text: "Error: #{error.to_s}",
      blocks: [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": error_text(error)
          }
        }
      ]
    )
  end

  #
  # Returns human-readable error text given an error type
  #
  # @param [StandardError or Symbol] error The raw exception (if thrown by the Pingity Gem) or a customized error code as a symbol
  #
  # @return [String] Human-readable error text in markdown format for posting
  #
  def error_text(error)
    case error
    when StandardError
      ERROR_TEXT[error.class]
    else
      ERROR_TEXT[error]
    end
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

  extend self
end
