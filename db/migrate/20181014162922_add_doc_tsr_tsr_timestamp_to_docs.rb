class AddDocTsrTsrTimestampToDocs < ActiveRecord::Migration[5.1]
  def change
    add_column :docs, :doc_tsr, :text
    add_column :docs, :tsr_timestamp, :string
  end
end
