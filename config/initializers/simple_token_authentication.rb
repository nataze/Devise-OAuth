SimpleTokenAuthentication.configure do |config|

  config.sign_in_token = true

  { user: { authentication_token: 'X-User-Token', email: 'X-User-Email' } }

  config.skip_devise_trackable = false

end