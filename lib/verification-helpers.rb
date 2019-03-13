def verify_token(token)
  unless SLACK_CONFIG[:slack_verification_token] == token
    halt 403, "Invalid Slack verification token received: #{token}"
  end
end
