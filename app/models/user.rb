class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :passkey_credentials, dependent: :destroy
  has_many :usage_logs, dependent: :delete_all
  has_many :bookmarks, dependent: :destroy
  has_one_attached :avatar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :email_verification, expires_in: 2.days do
    email_address
  end

  before_create :generate_webauthn_id

  def verified?
    verified
  end

  PLANS = {
    "free" => {
      name: "Free", price: 0,
      features: %w[downloader profilePicture]
    },
    "basic" => {
      name: "Basic", price: 4,
      features: %w[downloader fullQuality batch profilePicture stories viewer profileAnalyzer]
    },
    "pro" => {
      name: "Pro", price: 9,
      features: %w[downloader fullQuality batch profilePicture stories viewer profileAnalyzer influencerSearch hashtagGenerator]
    }
  }.freeze

  def current_plan
    plan.presence || "free"
  end

  def plan_config
    PLANS[current_plan]
  end

  def can_access?(feature)
    PLANS[current_plan][:features].include?(feature.to_s)
  end

  private

  def generate_webauthn_id
    self.webauthn_id ||= SecureRandom.urlsafe_base64(32)
  end
end
