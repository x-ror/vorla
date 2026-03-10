class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

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
end
