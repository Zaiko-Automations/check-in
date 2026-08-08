class AddUnitToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :unit, null: true, foreign_key: true
  end
end
