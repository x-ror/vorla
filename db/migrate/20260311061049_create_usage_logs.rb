class CreateUsageLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :usage_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action_type, null: false
      t.string :ip_address, null: false
      t.string :session_token
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :usage_logs, [ :action_type, :ip_address, :created_at ]
    add_index :usage_logs, [ :action_type, :user_id, :created_at ]
    add_index :usage_logs, :created_at
  end
end
