class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  Rails.application.config.session_store :memory_store, key: '_minderly_bot_app'
  $user_details = {}
  $important_days = {}
  $birthdays = {}
  $anniversaries = {}
  $messages = []
  $names = ''
  def start!(*)
    greetings = %w[
      bonjour hola hallo sveiki namaste shalom salaam szia halo ciao
    ]

    first_name = from ? ', ' + from['first_name'] : ''
    send_message "#{greetings.sample.capitalize}#{first_name}!\n Enter /help for options."
  end

  def help!(*)
    commands = Rails.configuration.bot_commands
    send_message "Please enter any of the following commands: #{commands}"
  end

  def stop!(*)
    send_message "Bye, #{from['first_name']}!"
  end

  def subscribe!(*)
    message = payload
    $user_details[:chat_id] = message['chat']['id']
    #  user_details[:sex] = @sex

    first_name = from ? from['first_name'] : 'channel'
    $user_details[:first_name] = first_name

    last_name = from ? from['last_name'] : ''
    $user_details[:last_name] = last_name

    user_name = from ? from['username'] : ''
    $user_details[:username] = user_name

    # set context for the next message
    save_context :add_gender
    context_message = 'Please enter [m]ale or [f]emale for male or female respectively'
    $messages << context_message
    send_message context_message
  end

  def add_gender(gender)
    valid = true
    case gender[0].downcase
    when 'm'
      $user_details[:gender] = 'M'
    when 'f'
      $user_details[:gender] = 'F'
    else
      valid = false
    end
    if valid
      $messages.pop
      context_message = "Enter your birthday in the format 'DD/MM/YYYY'"
      $messages << context_message
      send_message context_message
      save_context :add_my_birthday
    else
      send_message $messages[-1]
      save_context :add_gender
    end
  end

  def add_my_birthday(date)
    begin
      $user_details[:birthday] = Date.parse(date.strip)
    rescue StandardError => e
      send_message "#{e}: Incorrect format for birthday date entry."
      send_message $messages[-1]
      save_context :add_my_birthday
    end
    $messages.pop
    context_message = "Please add at least one birthday to be reminded of.\n"\
    'Please enter the name of the person whose birthday you would like to save'
    $messages << context_message
    send_message context_message
    save_context :add_birthday_details!
  end

  def add_birthday_details!(name)
    $names = name
    context_message = "Enter the birthday in the format 'DD/MM/YYYY'"
    $messages << context_message
    send_message context_message
    save_context :add_birthday
  end

  def add_birthday(date)
    names = $names.strip.split(' ')
    names.map!(&:capitalize)
    begin
      $birthdays[names.join(' ')] = Date.parse(date.strip)
    rescue StandardError => e
      send_message "#{e}: Incorrect format for birthday date entry."
      send_message $messages[-1]
      save_context :add_birthday
    end
    $names = ''
    $important_days[:birthdays] = $birthdays
    send_message 'The birthday has been successfully added.'
    $messages.pop
    context_message = "Please add at least one anniversary to be reminded of.\n"\
    'Please enter the name of the couple whose anniversary you would like to save'
    $messages << context_message
    send_message context_message
    save_context :add_anniversary_details!
  end

  def add_anniversary_details!(name)
    $names = name
    context_message = "Enter the anniversary in the format 'DD/MM/YYYY'"
    $messages << context_message
    send_message context_message
    save_context :add_anniversary
  end

  def add_anniversary(date)
    names = $names.strip.split(' ')
    names.map! do |name|
      if name.downcase == 'and'
        name
      else
        name.capitalize
      end
    end

    begin
      anniversary_date = Date.parse(date.strip)
      $anniversaries[names.join(' ')] = anniversary_date
    rescue StandardError => e
      send_message "#{e}: Incorrect format for anniversary date entry."
      send_message $messages[-1]
      save_context :add_anniversary
    end
    $names = ''
    $important_days[:anniversaries] = $anniversaries
    send_message 'The anniversary has been successfully added.'
    $messages.pop
    subscribe_user
  end

  def subscribe_user
    $user_details[:important_days] = $important_days
    user = User.new($user_details)
    if user.save
      send_message 'Your subscription was successful.'

    else
      send_message "You are already subscribed, please enter '/update'"\
       'to update your subscription'
    end
  end

  def action_missing(_action, *_args)
    text = t('telegram_webhooks.action_missing.command', command: action_options[:command])
    send_message text unless action_type == :command
    # if action_type == :command
    #   # respond_with :message,
    #               #  text: t('telegram_webhooks.action_missing.command', command: action_options[:command])
    # end
  end

  def send_message(text)
    respond_with :message, text: text
  end
end
