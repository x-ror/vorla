class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :bookmark_type, null: false
      t.string :title
      t.string :instagram_username

      t.timestamps
    end

    add_index :bookmarks, [ :user_id, :url ], unique: true
    add_index :bookmarks, [ :user_id, :bookmark_type ]
  end
end
