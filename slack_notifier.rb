# frozen_string_literal: true

require 'net/http'
require 'json'

class SlackNotifier
  def initialize
    @webhook_url = 'https://hooks.slack.com/services/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'
  end

  def notify(message, options = {})
    payload = {
      channel: 'C05NKLP36R0',
      text: message,
      username: options[:username] || 'Notifier',
      icon_emoji: options[:icon_emoji] || ':white_check_mark:'
    }

    send_payload(payload)
  end

  private

  def send_payload(payload)
    uri = URI(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = payload.to_json

    response = http.request(request)

    return if response.is_a?(Net::HTTPSuccess)

    puts "Slack通知エラー: #{response.code} - #{response.body}"
  end
end
