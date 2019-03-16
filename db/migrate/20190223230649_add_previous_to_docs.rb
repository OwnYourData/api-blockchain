class AddPreviousToDocs < ActiveRecord::Migration[5.1]
  def change
    add_column :docs, :previous, :integer
  end
end
