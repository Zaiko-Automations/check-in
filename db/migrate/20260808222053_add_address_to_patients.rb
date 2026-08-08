class AddAddressToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :logradouro, :string
    add_column :patients, :numero, :string
    add_column :patients, :bairro, :string
    add_column :patients, :cidade, :string
    add_column :patients, :uf, :string
    add_column :patients, :cep, :string
    add_column :patients, :complemento, :string
  end
end
