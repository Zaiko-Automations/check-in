class CreateUnits < ActiveRecord::Migration[7.1]
  def change
    create_table :units do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :token, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :units, :token, unique: true
    add_index :units, [:tenant_id, :name]
  end
end
