require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
# require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
# Bundler.require(*Rails.groups)
Bundler.require(*Rails.groups(
  assets: %i[development test],
  pry:    %i[development test],
))

module MinderlyBot
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.bot_commands = [
      '/start',
      '/help',
      '/stop',
      '/news',
      '/change_my_birthday',
      '/change_or_add_birthday',
      '/change_or_add_anniversary',
      '/subscribe',
      '/update'
    ]
    config.default_important_days = {
      Christmas: [Date.parse("25/12/#{Date.today.year}"), 'Wishing you a Merry Christmas', 'B'],
      Fathers_Day: [Date.parse("21/06/#{Date.today.year}"), 'Happy Father\'s day', 'M'],
      Mothers_Day: [Date.parse("10/05/#{Date.today.year}"), 'Happy Mother\'s day', 'F']
    }

    config.group_id = {}
  end
end
