class RemoveTenantFromWalkInsAndUnits < ActiveRecord::Migration[7.1]
  def change
    remove_reference :walk_ins, :tenant, null: false, foreign_key: true
    remove_reference :units,    :tenant, null: false, foreign_key: true
  end
end
