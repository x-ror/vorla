class CreateBookmarkItems < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmark_items do |t|
      t.references :bookmark, null: false, foreign_key: true
      t.string :media_url, null: false
      t.string :media_type # photo, video
      t.string :title

      t.timestamps
    end

    add_index :bookmark_items, [ :bookmark_id, :media_url ], unique: true
  end
end
