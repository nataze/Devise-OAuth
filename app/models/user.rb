class User < ActiveRecord::Base

  before_create :set_expiration


  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  acts_as_token_authenticatable
  

  validates_format_of :email, :without => TEMP_EMAIL_REGEX, on: :update

  def set_expiration
    self.token_expires_at = DateTime.now + 10.minutes
  end

  def token_expired?
    DateTime.now >= self.token_expires_at
  end

  def create_token
    if self.token_expired?
      self.authentication_token = nil
      self.save
    end
  end


  def self.find_for_oauth(auth, signed_in_resource = nil)
    # get identity of user if they exist
    identity = Identity.find_for_oauth(auth)

    user = signed_in_resource ? signed_in_resource : identity.user

    # Create the user if needed
    if user.nil?
      # Get user by email if provider gives a verified email
      # if not we assign a temporary email and ask the user to verify via UserController.finish_signup
      email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(:email => email).first if email

      # Create the user if its a new registration
      if user.nil?
        user = User.new(
          name: auth.extra.raw_info.name,
          #username: auth.info.nickname || auth.uid,
          email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
          password: Devise.friendly_token[0,20]  
        )
        # user.skip_confirmation!
        user.save!
      end
    end

    # Associate the identity with the user if needed
    if identity.user != user
      identity.user = user
      identity.save!
    end
    user
  end 

  def email_verified?
    self.email && self.email !~ TEMP_EMAIL_REGEX
  end

end
