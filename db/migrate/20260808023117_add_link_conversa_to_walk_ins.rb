class AddLinkConversaToWalkIns < ActiveRecord::Migration[7.1]
  def change
    add_column :walk_ins, :link_conversa, :string
  end
end
