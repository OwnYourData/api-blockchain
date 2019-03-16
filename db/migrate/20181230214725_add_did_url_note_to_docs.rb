class AddDidUrlNoteToDocs < ActiveRecord::Migration[5.1]
  def change
    add_column :docs, :did, :string
    add_column :docs, :url, :string
    add_column :docs, :note, :text
  end
end
