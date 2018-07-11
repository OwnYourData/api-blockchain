class CreateDocs < ActiveRecord::Migration[5.1]
  def change
    create_table :docs do |t|
      t.integer :merkle_id
      t.string :doc_hash

      t.timestamps
    end
  end
end
