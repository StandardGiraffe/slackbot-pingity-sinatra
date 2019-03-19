def monitor_header_blocks(uri:, endtime:)
  [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*<https://pingity.com|Pingty>* is monitoring *\"#{uri}\"* until <!date^#{endtime}^{date_short_pretty} at {time}|Timestamp unavailable, sorry.>"
      }
    }
  ]
end
