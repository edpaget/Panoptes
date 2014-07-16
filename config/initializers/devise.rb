Devise.setup do |config|
  config.mailer_sender = 'no-reply@zooniverse.org'

  require 'devise/orm/active_record'

  config.authentication_keys = [ :login ]
  config.case_insensitive_keys = [ :login, :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 10
  config.reconfirmable = true
  config.password_length = 4..128
  config.reset_password_within = 6.hours

  config.sign_out_via = :delete

  # OMNIAUTH
  
  def load_social_config
    config = YAML.load(ERB.new(File.read(Rails.root.join('config/social.yml'))).result)
    config[Rails.env].symbolize_keys
  end

  def social_config
    @social_config ||= load_social_config
  end

  def omniauth_config_for(config, providers: provider)
    providers.each do |provider|
      conf = social_config[provider]
      config.omniauth provider, conf.delete('app_id'), conf.delete('app_secret'), **conf
    end
  end

  omniauth_config_for(config, providers: [:facebook, :gplus])
end

