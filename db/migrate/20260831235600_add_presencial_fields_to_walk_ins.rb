class AddPresencialFieldsToWalkIns < ActiveRecord::Migration[7.1]
  def change
    add_column :walk_ins, :origem, :string, default: 'qrcode', null: false
    add_column :walk_ins, :prioridade, :string, default: 'geral', null: false
    add_column :walk_ins, :numero_senha, :string

    add_index :walk_ins, :origem
    add_index :walk_ins, :prioridade
  end
end
