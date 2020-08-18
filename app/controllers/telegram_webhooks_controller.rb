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
    chat_id = message['chat']['id']
    user = User.find_by(chat_id: chat_id)
    unless user.nil?
      send_message "You are already subscribed, please enter '/update'"\
         'to update your subscription'
    end

    $user_details[:chat_id] = chat_id

    first_name = from ? from['first_name'] : 'channel'
    $user_details[:first_name] = first_name

    last_name = from ? from['last_name'] : ''
    $user_details[:last_name] = last_name

    user_name = from ? from['username'] : ''
    $user_details[:username] = user_name

    prompt_user :add_gender, 'Please enter [m]ale or [f]emale for male or female respectively'
  end

  def add_gender(gender)
    context_message = "Enter your birthday in the format 'DD/MM/YYYY'"
    case gender[0].downcase
    when 'm'
      $user_details[:gender] = 'M'
      prompt_user :add_my_birthday, context_message
    when 'f'
      $user_details[:gender] = 'F'
      prompt_user :add_my_birthday, context_message
    else
      send_message $messages[-1]
      save_context :add_gender
    end
  end

  def add_my_birthday(date)
    date = retrieve_date date, :add_my_birthday
    return unless date

    $user_details[:birthday] = date
    context_message = "Please add at least one birthday to be reminded of.\n"\
    'Please enter the name of the person whose birthday you would like to save'
    prompt_user :add_birthday_details!, context_message
  end

  def add_birthday_details!(name)
    $names = name
    prompt_user :add_birthday, "Enter the birthday in the format 'DD/MM/YYYY'"
  end

  def add_birthday(date)
    names = $names.strip.split(' ')
    names.map!(&:capitalize)

    date = retrieve_date date, :add_birthday
    return unless date

    $birthdays[names.join(' ')] = date
    $important_days[:birthdays] = $birthdays
    send_message 'The birthday has been successfully added.'

    context_message = "Please add at least one anniversary to be reminded of.\n"\
    'Please enter the name of the couple whose anniversary you would like to save'

    prompt_user :add_anniversary_details!, context_message
  end

  def retrieve_date(date, context)
    begin
      date = Date.parse(date.strip)
    rescue StandardError => e
      send_message "#{e}: Incorrect format for birthday date entry."
      send_message $messages[-1]
      save_context context
    end
    date
  end

  def add_anniversary_details!(name)
    $names = name
    prompt_user :add_anniversary, "Enter the anniversary in the format 'DD/MM/YYYY'"
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

    date = retrieve_date date, :add_anniversary
    return unless date

    $anniversaries[names.join(' ')] = date
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
      send_message "#{user.errors.full_messages} The subscription failed, please try again"
    end
  end

  def action_missing(_action, *_args)
    text = t('telegram_webhooks.action_missing.command', command: action_options[:command])
    send_message text unless action_type == :command
  end

  def update!(*)
    message = payload
    chat_id = message['chat']['id']
    user = User.find_by(chat_id: chat_id)
    if user.nil?
      send_message "The user subscription doesn't exist. Please enter "\
      '/subscribe to subscribe'
    end

    prompt_user :update_my_birthday?, 'Please  enter y[es] or n[o] if would like to update your birthday'
  end

  def update_my_birthday?(answer)
    case answer[0].downcase
    when 'y'
      prompt_user :update_my_birthday, "Enter your birthday in the format 'DD/MM/YYYY'"
    when 'n'
      context_message = 'Please  enter y[es] or n[o] if you would like to update or add a birthday'
      $messages << context_message
      send_message context_message
      prompt_user :update_birthday?, context_message
    else
      send_message $messages[-1]
      save_context :update_my_birthday?
    end
  end

  def update_my_birthday(date)
    date = retrieve_date date, :update_my_birthday
    return unless date

    $user_details[:birthday] = date
    prompt_user :update_birthday?, 'Please enter y[es] or n[o] if you would like to update or add a birthday'
  end

  def update_birthday?(answer)
    case answer[0].downcase
    when 'y'
      context_message = 'Please enter the name of the person whose birthday you would like to update'
      prompt_user :update_birthday_details, context_message
    when 'n'
      prompt_user :update_anniversary?, 'Please  enter y[es] or n[o] if would like to update or add an anniversary'
    else
      send_message $messages[-1]
      save_context :update_my_birthday?
    end
  end

  def update_birthday_details(name)
    $names = name
    prompt_user :update_birthday, "Enter the birthday in the format 'DD/MM/YYYY'"
  end

  def update_birthday(date)
    names = $names.strip.split(' ')
    names.map!(&:capitalize)
    date = retrieve_date date, :update_birthday
    return unless date

    $birthdays[names.join(' ')] = date
    send_message 'The birthday has been successfully added.'

    prompt_user :update_anniversary?, 'Please  enter y[es] or n[o] if would like to update or add an anniversary'
  end

  def update_anniversary?(answer)
    case answer[0].downcase
    when 'y'
      context_message = 'Please enter the name of the person whose anniversary you would like to update'
      prompt_user :update_anniversary_details, context_message
    when 'n'
      update_user
    else
      send_message $messages[-1]
      save_context :update_my_birthday?
    end
  end

  def update_anniversary_details(name)
    $names = name
    prompt_user :update_anniversary, "Enter the anniversary in the format 'DD/MM/YYYY'"
  end

  def update_anniversary(date)
    names = $names.strip.split(' ')
    names.map! do |name|
      if name.downcase == 'and'
        name
      else
        name.capitalize
      end
    end

    date = retrieve_date date, :update_anniversary
    return unless date

    $anniversaries[names.join(' ')] = date
    $names = ''
    send_message 'The anniversary has been successfully added.'
    $messages.pop
    update_user
  end

  def update_user
    # user = User.find_by(chat_id: chat_id)
    # user.update()
    # Pass in a hash of attributes to update
    # Use `parse_yaml` to convert yaml attribute to hash before updating
  end

  def prompt_user(context, context_message)
    $messages.pop unless $messages.empty?
    $messages << context_message
    send_message context_message
    save_context context
  end

  def send_message(text)
    respond_with :message, text: text
  end
end
