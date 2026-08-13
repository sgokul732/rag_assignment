class CreateChunks < ActiveRecord::Migration[7.1]
  def change
    create_table :chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content, null: false
      t.string :embedding_model
      # Store embedding as JSON
      t.json :embedding
      
      t.timestamps
    end
  end
end
