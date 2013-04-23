Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, "Your Google Id", "Your Google Secret" , {
             :scope => "userinfo.email,userinfo.profile",
             :approval_prompt => ""
  }
end

OmniAuth.config.logger = Rails.logger
