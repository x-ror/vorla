class AddPostedAtToBookmarks < ActiveRecord::Migration[8.1]
  def change
    add_column :bookmarks, :posted_at, :datetime
    add_column :bookmarks, :author, :string
    add_column :bookmarks, :caption, :text
  end
end
