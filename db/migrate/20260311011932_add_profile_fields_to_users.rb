class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :full_name, :string
    add_column :users, :bio, :text
    add_column :users, :avatar_url, :string
    add_column :users, :instagram_username, :string
    add_column :users, :instagram_id, :string
    add_column :users, :instagram_connected_at, :datetime
  end
end
