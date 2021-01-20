require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pericles_GWGw
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'mapper', '**/')]
    config.autoload_paths += Dir[Rails.root.join('app', 'errors', '**/')]

    # Enable the asset pipeline
    config.assets.enabled = true

    config.cache_store = :memory_store

    config.active_job.queue_adapter = :delayed_job

    if ENV['S3_BUCKET_NAME'].present?
      config.paperclip_defaults = {
        storage: :s3,
        s3_host_name: 's3-eu-west-1.amazonaws.com',
        s3_credentials: {
          bucket: ENV['S3_BUCKET_NAME'],
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
        }
      }
    end

    config.internal_email_domain = ENV['INTERNAL_EMAIL_DOMAIN']
  end
end
