class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.string :source
      
      t.timestamps
    end
    
    add_index :documents, :title
  end
end
