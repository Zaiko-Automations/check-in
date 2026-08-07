class CreateWalkIns < ActiveRecord::Migration[7.1]
  def change
    create_table :walk_ins do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.string :uid, null: false           # ex: wlk_20260704_abc123
      t.string :status, default: 'pending', null: false
      # status: pending | webhook_sent | completed | failed
      t.datetime :webhook_sent_at
      t.text :webhook_error
      t.timestamps
    end

    add_index :walk_ins, :uid, unique: true
    add_index :walk_ins, [:tenant_id, :status]
    add_index :walk_ins, :created_at
  end
end
