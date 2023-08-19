# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class SlackNotifier
  def initialize(webhook_url)
    @webhook_url = webhook_url
  end

  def send_message(text, channel: 'C05NKHPN30T', username: 'OGIXXX', icon_emoji: ':rocket:')
    payload = {
      text: text,
      channel: channel,
      username: username,
      icon_emoji: icon_emoji
    }.compact

    uri = URI.parse(@webhook_url)
    request = Net::HTTP::Post.new(uri)
    request.body = JSON.dump(payload)

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end
end

# 使用方法
webhook_url = 'https://hooks.slack.com/services/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'
notifier = SlackNotifier.new(webhook_url)
notifier.send_message('送信しました', channel: 'C05NKLP36R0', username: 'Messenger', icon_emoji: ':white_check_mark:')
