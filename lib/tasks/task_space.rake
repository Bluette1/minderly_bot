require_relative '../../app/lib/important_day_checker'
require_relative '../../app/lib/feed_messenger'

require 'telegram/bot'

namespace :task_space do
  desc 'TODO'
  task check_special_days: :environment do
    check_today
  end

  task check_latest_news: :environment do
    send_news
  end
end

def check_today(user = nil)
  day_checker = ImportantDayChecker.new(
    config: {
      default_important_days: Rails.configuration.default_important_days,
      group_id: group_id,
      channel_id: channel_id
    },
    bot: bot
  )
  day_checker.check_today(user)
end

def send_news(chat_id = nil)
  feeder = FeedMessenger.new(
    config: {
      group_id: group_id,
      channel_id: channel_id
    },
    bot: bot
  )
  feeder.send_feed(chat_id)
end

def bot
  token = Rails.application.secrets.telegram['bot']['token'] || ENV['BOT_TOKEN']
  username = Rails.application.secrets.telegram['bot']['username'] || ENV['BOT_USERNAME']
  Telegram::Bot::Client.new(token, username)
end

def group_id
  Rails.application.secrets.telegram['group_id'] || ENV['GROUP_ID']
end

def channel_id
  Rails.application.secrets.telegram['channel_id'] || ENV['CHANNEL_ID']
end
