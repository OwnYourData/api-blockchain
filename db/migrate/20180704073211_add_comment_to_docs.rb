class AddCommentToDocs < ActiveRecord::Migration[5.1]
  def change
    add_column :docs, :comment, :string
  end
end
