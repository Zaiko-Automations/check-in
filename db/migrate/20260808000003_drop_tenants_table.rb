class DropTenantsTable < ActiveRecord::Migration[7.1]
  def change
    # Remove foreign key from users table first, then drop tenants
    remove_reference :users, :tenant, foreign_key: true, null: true
    drop_table :tenants
  end
end
