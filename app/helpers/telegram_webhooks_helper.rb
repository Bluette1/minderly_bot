require_relative '../lib/important_day_checker'

module TelegramWebhooksHelper
  def send_greetings
    greetings = %w[
      bonjour hola hallo sveiki namaste shalom salaam szia halo ciao
    ]

    first_name = from ? ', ' + from['first_name'] : ''

    send_message "#{greetings.sample.capitalize}#{first_name}!\n Enter /help for options."
  end

  def send_options
    commands = Rails.configuration.bot_commands
    send_message "Please enter any of the following commands: #{commands}"
  end

  def send_message(text)
    respond_with :message, text: text
  end

  def save_user(user_details)
    user = User.new(user_details)
    if user.save
      send_message 'Your subscription was successful.'
    else
      send_message "#{user.errors.full_messages} The subscription failed, please try again"
    end
    check_today(user)
    send_news(user.chat_id)
  end

  def update_save_user(user, user_details)
    if user.update(user_details)
      send_message 'Your subscription was successfully updated.\n'\
      'You can use either of the commands:' \
                  " '/change_my_birthday', '/change_or_add_birthday', or '/change_or_add_anniversary'"\
                   ' to update your birthday, and change or add birthdays and anniversaries to be'\
                   ' reminded of respectively.'
      check_today(user)
      send_news(user.chat_id)

    else
      send_message "#{user.errors.full_messages} The subscription update failed, please try again"
    end
  end

  def check_today(user = nil)
    day_checker = ImportantDayChecker.new(
      config: {
        default_important_days: Rails.configuration.default_important_days,
        group_id: Rails.application.secrets.telegram['group_id'] || ENV['group_id'],
        channel_id: Rails.application.secrets.telegram['channel_id'] || ENV['channel_id']
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
    token = Rails.application.secrets.telegram['bot']['token'] || ENV[BOT_TOKEN]
    username = Rails.application.secrets.telegram['bot']['username'] || ENV[BOT_USERNAME]
    Telegram::Bot::Client.new(token, username)
  end

  def group_id
    Rails.application.secrets.telegram['group_id'] || ENV['group_id']
  end

  def channel_id
    Rails.application.secrets.telegram['channel_id'] || ENV['channel_id']
  end
end
