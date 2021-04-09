require 'slack-ruby-client'
require 'sinatra'
require 'cloud_events'
require 'json'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client = Slack::Web::Client.new
client.auth_test

cloud_events_http = CloudEvents::HttpBinding.default

post "/" do
  event = cloud_events_http.decode_rack_env request.env
  data = JSON.parse(event["data"])
  logger.info data["message"]
  logger.info data["user"]
  logger.info "Received CloudEvent: #{event.to_h}"

  eMessage = "New comment from #{data["user"]} on #{data["owner"]}/#{data["repo"]}
  
  > #{data["message"]}
  "

  client.chat_postMessage(channel: '#general', text: eMessage, as_user: true)
end