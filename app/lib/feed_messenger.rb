require 'rss'
require 'open-uri'

class FeedMessenger
  attr_reader :bot, :config

  def initialize(options)
    @bot = options [:bot]
    @config = options [:config]
    @urls = [
      'https://www.history.com/.rss/full/this-day-in-history',
      'https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml',
      'https://rss.nytimes.com/services/xml/rss/nyt/Science.xml',
      'https://rss.nytimes.com/services/xml/rss/nyt/Arts.xml',
      'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml'
    ]
  end

  def send_feed(chat_id = nil)
    check_news chat_id
  end

  private

  def check_news(chat_id = nil)
    @urls.each do |url|
      news = {}
      URI.parse(url).open do |rss|
        feed = RSS::Parser.parse(rss)
        channel = pre_post_append feed.channel.title
        feed.items.each do |item|
          title = item.title
          news[title.to_sym] = item.link
        end

        if chat_id.nil?
          send_to_users news, channel
        else
          send_to_users news, channel, chat_id
        end
      end
    end
  end

  def pre_post_append(channel)
    channel = if channel.match?(/...History.../i)
                channel.center(58, '=')
              else
                channel.center(81, '-')
              end
    channel
  end

  def send_to_users(news, channel, chat_id = nil)
    users = User.all
    choice = rand(5)
    news_item = choose_news_item choice, news, channel
    if chat_id.nil?
      users.each do |user|
        feed user.chat_id, news_item
      end
    else
      feed chat_id, news_item
    end
  end

  def feed(chat_id, news_item)
    send_rss news_item, chat_id

    send_rss news_item, config[:group_id] unless config[:group_id].nil?

    send_rss news_item, config[:channel_id] unless config[:channel_id].nil?
  end

  def choose_news_item(choice, news, channel)
    news_item = {}
    index = 0
    news.each do |title, link|
      if choice == index
        news_item = {}
        news_item[:channel] = channel
        news_item[:title] = title
        news_item[:link] = link
        break
      end
      index += 1
    end
    news_item
  end

  def send_rss(news_item, chat_id)
    channel = news_item[:channel]
    title = news_item[:title]
    link = news_item[:link]

    @bot.send_message(chat_id: chat_id, text: "#{channel}\n#{title}\n#{link}")
  end
end
