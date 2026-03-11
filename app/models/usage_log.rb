class UsageLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action_type, presence: true
  validates :ip_address, presence: true

  LIMITS = YAML.load_file(Rails.root.join("config/usage_limits.yml")).freeze

  ACTION_TYPES = LIMITS.keys.freeze
  validates :action_type, inclusion: { in: ACTION_TYPES }

  scope :recent, -> { where(created_at: 24.hours.ago..) }
  scope :for_action, ->(action) { where(action_type: action) }

  def self.usage_count(action_type:, user: nil, ip_address: nil)
    scope = recent.for_action(action_type)
    scope = user ? scope.where(user: user) : scope.where(ip_address: ip_address, user: nil)
    scope.count
  end

  def self.limit_for(action_type, user: nil)
    limits = LIMITS[action_type]
    return nil unless limits

    user ? limits["user"] : limits["guest"]
  end

  def self.remaining(action_type:, user: nil, ip_address: nil)
    limit = limit_for(action_type, user: user)
    return nil unless limit

    used = usage_count(action_type: action_type, user: user, ip_address: ip_address)
    [ limit - used, 0 ].max
  end

  def self.limit_reached?(action_type:, user: nil, ip_address: nil)
    remaining = self.remaining(action_type: action_type, user: user, ip_address: ip_address)
    return false if remaining.nil?

    remaining <= 0
  end
end
