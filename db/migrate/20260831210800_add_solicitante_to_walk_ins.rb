class AddSolicitanteToWalkIns < ActiveRecord::Migration[7.1]
  def change
    add_column :walk_ins, :solicitante_nome, :string
    add_column :walk_ins, :solicitante_conselho, :string
    add_column :walk_ins, :solicitante_especialidade, :string
    add_column :walk_ins, :data_pedido_medico, :date
  end
end
