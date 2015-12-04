class ApplicationController < ActionController::Base

  acts_as_token_authentication_handler_for User

  def ensure_signup_complete

    # ENsure we don't go into an infinite loop
    return if action_name == 'finish_signup'

    # Redirect to the finish_signup page if the user
    # email hasn't been verified yet
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end

  def expired_token
    if current_user && current_user.token_expired?
      redirect_to '/users/signout'
      sign_out current_user    
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    '/users/signout'
  end

  
  def after_sign_in_path_for(resource)
    current_user.create_token
  end


  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


end
