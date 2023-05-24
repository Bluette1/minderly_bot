class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  include TelegramWebhooksHelper
  rescue_from Telegram::Bot::Error, with: :error_generic
  rescue_from Exception, with: :error_generic

  Rails.application.config.session_store :memory_store, key: '_minderly_bot_app'
  @@user_details = {}
  @@important_days = {}
  @@birthdays = {}
  @@anniversaries = {}
  @@messages = []
  @@names = ''
  @@ongoing_subscribe = false

  def start!(*)
    send_greetings
    check_today
  end

  def help!(*)
    send_options
  end

  def stop!(*)
    send_message "Bye, #{from['first_name']}!"
  end

  def news!(*)
    send_news chat['id']
  end

  def message(message)
    respond_with :message, text: message['text'] unless message['text'].nil?
    send_options
  end

  def subscribe!(*)
    find_user
    unless @@user.nil?
      send_message "You are already subscribed, please enter '/update'"\
        'to update your subscription'
      return
    end

    @@ongoing_subscribe = true

    @@user_details[:chat_id] = @@chat_id

    first_name = from ? from['first_name'] : 'channel'
    @@user_details[:first_name] = first_name

    last_name = from ? from['last_name'] : ''
    @@user_details[:last_name] = last_name

    user_name = from ? from['username'] : ''
    @@user_details[:username] = user_name

    prompt_user :add_gender, 'Please enter [m]ale or [f]emale for male or female respectively'
  end

  def add_gender(gender, *_args)
    context_message = "Enter your birthday in the format 'DD/MM/YYYY'"
    case gender[0].downcase
    when 'm'
      @@user_details[:gender] = 'M'
      prompt_user :add_my_birthday, context_message
    when 'f'
      @@user_details[:gender] = 'F'
      prompt_user :add_my_birthday, context_message
    else
      send_message @@messages[-1]
      save_context :add_gender
    end
  end

  def change_my_birthday!
    prompt_user :add_my_birthday, "Enter your birthday in the format 'DD/MM/YYYY'"
  end

  def add_my_birthday(date, *_args)
    date = retrieve_date date, :add_my_birthday
    return unless date

    @@user_details[:birthday] = date

    if @@ongoing_subscribe
      context_message = "Please add at least one birthday to be reminded of.\n"\
      'Please enter the name of the person whose birthday you would like to save'
      prompt_user :add_birthday_details, context_message
    else
      find_user
      update_save_user @@user, @@user_details
    end
  end

  def add_birthday_details(first_name = '', last_name = '', *_args)
    @@names = first_name << ' ' << last_name
    prompt_user :add_birthday, "Enter the birthday in the format 'DD/MM/YYYY'"
  end

  def change_or_add_birthday!
    context_message = 'Please enter the name of the person whose birthday you would like to save'
    prompt_user :add_birthday_details, context_message
  end

  def add_birthday(date, *_args)
    names = @@names.strip.split(' ')
    names.map!(&:capitalize)

    date = retrieve_date date, :add_birthday
    return unless date

    @@birthdays[names.join(' ')] = date
    @@important_days[:birthdays] = @@birthdays
    send_message 'The birthday has been successfully added.'
    if @@ongoing_subscribe
      context_message = "Please add at least one anniversary to be reminded of.\n"\
      'Please enter the name of the couple whose anniversary you would like to save'

      prompt_user :add_anniversary_details, context_message
    else
      find_user
      update_user
    end
  end

  def retrieve_date(date, context)
    begin
      date = Date.parse(date.strip)
    rescue StandardError => e
      send_message "#{e}: Incorrect format for birthday date entry."
      send_message @@messages[-1]
      save_context context
    end
    date
  end

  def add_anniversary_details(first_name = '', last_name = '', *_args)
    @@names = first_name << last_name
    prompt_user :add_anniversary, "Enter the anniversary in the format 'DD/MM/YYYY'"
  end

  def change_or_add_anniversary!
    context_message = 'Please enter the name of the couple whose anniversary you would like to save'

    prompt_user :add_anniversary_details, context_message
  end

  def add_anniversary(date, *_args)
    names = @@names.strip.split(' ')
    names.map! do |name|
      if name.downcase == 'and'
        name
      else
        name.capitalize
      end
    end

    date = retrieve_date date, :add_anniversary
    return unless date

    @@anniversaries[names.join(' ')] = date
    @@names = ''
    @@important_days[:anniversaries] = @@anniversaries
    send_message 'The anniversary has been successfully added.'
    @@messages.pop
    if @@ongoing_subscribe
      subscribe_user
    else
      find_and_update_user
    end
  end

  def find_and_update_user
    find_user
    update_user
  end

  def subscribe_user
    @@user_details[:important_days] = @@important_days
    save_user @@user_details
    clear
  end

  def action_missing(_action, *_args)
    text = t('telegram_webhooks.action_missing.command', command: action_options[:command])
    send_message text unless action_type == :command
  end

  def update!(*)
    find_user

    if @@user.nil?
      send_message "The user subscription doesn't exist. Please enter "\
      '/subscribe to subscribe'
      nil
    else
      prompt_user :update_my_birthday?, 'Please  enter y[es] or n[o] if would like to update your birthday'
    end
  end

  def update_my_birthday?(answer)
    case answer[0].downcase
    when 'y'
      prompt_user :update_my_birthday, "Enter your birthday in the format 'DD/MM/YYYY'"
    when 'n'
      context_message = 'Please enter y[es] or n[o] if you would like to update or add a birthday'
      prompt_user :update_birthday?, context_message
    else
      send_message @@messages[-1]
      save_context :update_my_birthday?
    end
  end

  def update_my_birthday(date, *_args)
    date = retrieve_date date, :update_my_birthday
    return unless date

    @@user_details[:birthday] = date
    prompt_user :update_birthday?, 'Please enter y[es] or n[o] if you would like to update or add a birthday'
  end

  def update_birthday?(answer, *_args)
    case answer[0].downcase
    when 'y'
      context_message = 'Please enter the name of the person whose birthday you would like to add or update'
      prompt_user :update_birthday_details, context_message
    when 'n'
      prompt_user :update_anniversary?, 'Please  enter y[es] or n[o] if would like to update or add an anniversary'
    else
      send_message @@messages[-1]
      save_context :update_birthday?
    end
  end

  def update_birthday_details(name, *_args)
    @@names = name
    prompt_user :update_birthday, "Enter the birthday in the format 'DD/MM/YYYY'"
  end

  def update_birthday(date, *_args)
    names = @@names.strip.split(' ')
    names.map!(&:capitalize)
    date = retrieve_date date, :update_birthday
    return unless date

    @@birthdays[names.join(' ')] = date
    send_message 'The birthday has been successfully added.'

    prompt_user :update_anniversary?, 'Please  enter y[es] or n[o] if would like to update or add an anniversary'
  end

  def update_anniversary?(answer, *_args)
    case answer[0].downcase
    when 'y'
      context_message = 'Please enter the name of the couple whose anniversary you would like to add or update'
      prompt_user :update_anniversary_details, context_message
    when 'n'
      update_user
    else
      send_message @@messages[-1]
      save_context :update_anniversary?
    end
  end

  def update_anniversary_details(name, *_args)
    @@names = name
    prompt_user :update_anniversary, "Enter the anniversary in the format 'DD/MM/YYYY'"
  end

  def update_anniversary(date, *_args)
    names = @@names.strip.split(' ')
    names.map! do |name|
      if name.downcase == 'and'
        name
      else
        name.capitalize
      end
    end

    date = retrieve_date date, :update_anniversary
    return unless date

    @@anniversaries[names.join(' ')] = date
    send_message 'The anniversary has been successfully added.'
    @@names = ''
    @@messages.pop
    update_user
  end

  def update_user
    days = @@user.important_days
    @@important_days[:birthdays] = days[:birthdays].merge(@@birthdays)
    @@important_days[:anniversaries] = days[:anniversaries].merge(@@anniversaries)
    @@user_details[:important_days] = @@important_days
    update_save_user @@user, @@user_details
  end

  def prompt_user(context, context_message)
    @@messages.pop unless @@messages.empty?
    @@messages << context_message
    send_message context_message
    save_context context
  end

  def find_user
    @@chat_id = chat['id']
    @@user = User.find_by(chat_id: @@chat_id)
  end

  def error_generic(exception)
    puts "An error occurred: #{exception}"
  end

  def clear
    @@user_details = {}
    @@important_days = {}
    @@birthdays = {}
    @@anniversaries = {}
    @@messages = []
    @@names = ''
    @@ongoing_subscribe = false
  end
end
