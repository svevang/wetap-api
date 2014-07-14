class AuthTokenPair < ActiveRecord::Base
  belongs_to :user

  def self.generate_for(user)
    return user.auth_token_pair if user.auth_token_pair.present?

    auth = new
    auth.generate_tokens!
    auth.user = user
    user.auth_token_pair = auth
    auth.save
    return auth
  end

  def generate_tokens!
    self.private_token = AuthTokenPair.friendly_token_for(:private_token)
    self.public_token = AuthTokenPair.friendly_token_for(:public_token)
  end

  def self.friendly_token_for(attr)
    loop do
      token = Devise.friendly_token
      break token unless AuthTokenPair.find_by(attr => token)
    end
  end

end
