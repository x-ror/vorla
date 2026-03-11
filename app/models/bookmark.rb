class Bookmark < ApplicationRecord
  belongs_to :user

  TYPES = %w[post reel story account].freeze
  FREE_LIMIT = 20

  validates :url, presence: true
  validates :bookmark_type, presence: true, inclusion: { in: TYPES }
  validates :url, uniqueness: { scope: :user_id, message: "is already bookmarked" }
  validate :within_bookmark_limit, on: :create

  before_validation :normalize_url_and_detect_type

  scope :by_type, ->(type) { type.present? ? where(bookmark_type: type) : all }
  scope :recent, -> { order(created_at: :desc) }

  private

  def within_bookmark_limit
    return unless user

    limit = user.current_plan == "free" ? FREE_LIMIT : nil
    return unless limit

    if user.bookmarks.count >= limit
      errors.add(:base, "You've reached the maximum of #{limit} bookmarks. Upgrade your plan for unlimited bookmarks.")
    end
  end

  def normalize_url_and_detect_type
    return if url.blank?

    input = url.strip

    # Plain username (with or without @)
    if input.match?(/\A@?[\w.]+\z/) && !input.include?("/")
      username = input.delete_prefix("@")
      self.url = "https://www.instagram.com/#{username}/"
      self.bookmark_type = "account"
      self.instagram_username = username
      return
    end

    # Instagram URL patterns
    if input.match?(%r{instagram\.com/reel/})
      self.bookmark_type ||= "reel"
    elsif input.match?(%r{instagram\.com/p/})
      self.bookmark_type ||= "post"
    elsif input.match?(%r{instagram\.com/stories/})
      self.bookmark_type ||= "story"
      self.instagram_username ||= input.match(%r{/stories/([^/]+)})&.[](1)
    elsif input.match?(%r{instagram\.com/([^/?]+)})
      self.bookmark_type ||= "account"
      self.instagram_username ||= input.match(%r{instagram\.com/([^/?]+)})&.[](1)
    end
  end
end
