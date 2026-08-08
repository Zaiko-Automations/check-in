class CreateRequestedExams < ActiveRecord::Migration[7.1]
  def change
    create_table :requested_exams do |t|
      t.references :walk_in, null: false, foreign_key: true
      t.string :codigo
      t.string :descricao
      t.string :acuracia

      t.timestamps
    end
  end
end
