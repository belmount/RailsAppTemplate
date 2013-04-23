class User
  include Mongoid::Document
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:google_oauth2]
  field :name
  field :email
  field :confirmation_token
  field :encrypted_password
  field :remember_created_at
  field :current_sign_in_at
  field :last_sign_in_at
  field :current_sign_in_ip
  field :last_sign_in_ip
  field :sign_in_count

  validates_presence_of :name
  validates_uniqueness_of :name, :email, :case_sensitive => false    
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :provider,:uid, 
            :encrypted_password, :confirmed_at, :confirmation_sent_at, :encrypted_password, :confirmation_token
  has_many :authentications, :dependent => :delete
  
  # ===================================== #
  # ===================================== #
  # ==========  USER METHODS  =========== #
  # ===================================== #
  # ===================================== #
  def apply_omniauth(omniauth, confirmation)
    self.email = omniauth['user_info']['email'] if email.blank?
    # Check if email is already into the database => user exists
    apply_trusted_services(omniauth, confirmation) if self.new_record?
  end
  
  # Create a new user
  def apply_trusted_services(omniauth, confirmation)  
    # Merge user_info && extra.user_info
    user_info = omniauth['user_info']
    if omniauth['extra'] && omniauth['extra']['user_hash']
      user_info.merge!(omniauth['extra']['user_hash'])
    end  
    # try name or nickname
    if self.name.blank?
      self.name   = user_info['name']   unless user_info['name'].blank?
      self.name ||= user_info['nickname'] unless user_info['nickname'].blank?
      self.name ||= (user_info['first_name']+" "+user_info['last_name']) unless \
        user_info['first_name'].blank? || user_info['last_name'].blank?
    end   
    if self.email.blank?
      self.email = user_info['email'] unless user_info['email'].blank?
    end  
    # Set a random password for omniauthenticated users
    self.password, self.password_confirmation = Devise.friendly_token
    if (confirmation) 
      self.confirmed_at, self.confirmation_sent_at = Time.now  
    end 
  end
  
  
  # ===================================== #
  # ===================================== #
  # ========  OVERWRITE METHODS  ======== #
  # ===================================== #
  # ===================================== #
  def update_with_password(params={})
    current_password = params.delete(:current_password)
    check_password = true
    if params[:password].blank?
      params.delete(:password)
      if params[:password_confirmation].blank?
        params.delete(:password_confirmation)
        check_password = false
      end 
    end
    result = if valid_password?(current_password) || !check_password
      update_attributes(params)
    else
      self.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
      self.attributes = params
      false
    end
    clean_up_passwords
    result
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:email => data["email"]).first

    unless user
        user = User.create(name: data["name"],
             email: data["email"],
             password: Devise.friendly_token[0,20]
            )
    end
    user
end
end
