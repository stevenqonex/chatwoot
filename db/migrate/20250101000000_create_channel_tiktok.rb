class CreateChannelTiktok < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_tiktok do |t|
      t.string :business_id, null: false
      t.string :access_token, null: false
      t.datetime :expires_at, null: false
      t.string :webhook_verify_token
      t.jsonb :provider_config, default: {}
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_tiktok, :business_id, unique: true
    add_index :channel_tiktok, :account_id
  end
end
