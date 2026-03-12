class BookmarkItem < ApplicationRecord
  belongs_to :bookmark

  validates :media_url, presence: true
  validates :media_url, uniqueness: { scope: :bookmark_id }
end
