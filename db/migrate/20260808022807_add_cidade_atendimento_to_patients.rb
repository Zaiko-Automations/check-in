class AddCidadeAtendimentoToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :cidade_atendimento, :string
  end
end
