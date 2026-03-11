class AddVerifiedAndWebauthnToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :verified, :boolean, default: false, null: false
    add_column :users, :webauthn_id, :string
  end
end