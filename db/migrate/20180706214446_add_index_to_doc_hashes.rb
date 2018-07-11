class AddIndexToDocHashes < ActiveRecord::Migration[5.1]
  def change
    add_index :docs, :doc_hash
  end
end
