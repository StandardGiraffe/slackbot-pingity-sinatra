# This is a depricated method for verifying Slack as the sender.
def verify_token(token)
  unless SLACK_CONFIG[:slack_verification_token] == token
    halt 403, "Invalid Slack verification token received: #{token}"
  end

  puts "VERIFIED!"

  return 200
end

def verify_signature
  puts "Attempting to verify Slack's request..."

  signing_secret = ENV['SLACK_SIGNING_SECRET']
  version_number = 'v0' # always v0 for now
  timestamp = request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP']
  raw_body = request.body.read # raw body JSON string

  if Time.at(timestamp.to_i) < 5.minutes.ago
    # could be a replay attack
    puts "Stale request.  REJECTED."
    render nothing: true, status: :bad_request
    return
  end

  sig_basestring = [version_number, timestamp, raw_body].join(':')
  digest = OpenSSL::Digest::SHA256.new
  hex_hash = OpenSSL::HMAC.hexdigest(digest, signing_secret, sig_basestring)
  computed_signature = [version_number, hex_hash].join('=')
  slack_signature = request.env['HTTP_X_SLACK_SIGNATURE']

  if computed_signature != slack_signature
    puts "Signatures didn't match!  REJECTED."
    render nothing: true, status: :unauthorized
  end

  puts "Signatures match.  VERIFIED!"
end
