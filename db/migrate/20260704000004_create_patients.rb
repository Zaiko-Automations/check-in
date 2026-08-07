class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.references :walk_in, null: false, foreign_key: true

      # Dados pessoais
      t.string :nome, null: false
      t.string :cpf, null: false
      t.date   :data_nascimento
      t.string :sexo_biologico        # M | F
      t.string :telefone
      t.boolean :whatsapp, default: false

      # Cobertura
      t.string :cobertura_tipo, null: false   # particular | convenio
      t.string :convenio
      t.string :plano
      t.string :numero_carteira
      t.date   :validade_carteira

      t.timestamps
    end

    add_index :patients, :cpf
  end
end
