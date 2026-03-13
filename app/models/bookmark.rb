class Bookmark < ApplicationRecord
  belongs_to :user
  has_many :items, class_name: "BookmarkItem", dependent: :destroy

  TYPES = %w[post reel story account].freeze
  FREE_LIMIT = 20

  validates :url, presence: true
  validates :bookmark_type, presence: true, inclusion: { in: TYPES }
  validates :url, uniqueness: { scope: :user_id }
  validate :within_bookmark_limit, on: :create

  before_validation :detect_type

  scope :by_type, ->(type) { type.present? ? where(bookmark_type: type) : all }
  scope :recent, -> { order(created_at: :desc) }

  # Find or create bookmark for a source URL, then add the media item
  def self.add_item(user:, source_url:, media_url:, title: nil, media_type: nil, author: nil, caption: nil, posted_at: nil)
    bookmark = user.bookmarks.find_or_initialize_by(url: source_url)
    bookmark.title = title if title.present? && bookmark.title.blank?
    bookmark.author = author if author.present? && bookmark.author.blank?
    bookmark.caption = caption if caption.present? && bookmark.caption.blank?
    bookmark.posted_at = posted_at if posted_at.present? && bookmark.posted_at.blank?
    bookmark.save! if bookmark.new_record? || bookmark.changed?

    item = bookmark.items.find_or_initialize_by(media_url: media_url)
    item.title = title
    item.media_type = media_type
    item.save! if item.new_record? || item.changed?

    bookmark
  end

  private

  def within_bookmark_limit
    return unless user

    limit = user.current_plan == "free" ? FREE_LIMIT : nil
    return unless limit

    if user.bookmarks.count >= limit
      errors.add(:base, :bookmark_limit, limit: limit)
    end
  end

  def detect_type
    return if url.blank? || bookmark_type.present?

    input = url.strip

    if input.include?("instagram.com/reel/")
      self.bookmark_type = "reel"
    elsif input.include?("instagram.com/stories/")
      self.bookmark_type = "story"
      self.instagram_username = input.match(%r{/stories/([^/]+)})&.[](1)
    elsif input.include?("instagram.com/p/")
      self.bookmark_type = "post"
    elsif input.match?(%r{instagram\.com/([^/?]+)})
      self.bookmark_type = "account"
      self.instagram_username = input.match(%r{instagram\.com/([^/?]+)})&.[](1)
    else
      self.bookmark_type = "post"
    end
  end
end
