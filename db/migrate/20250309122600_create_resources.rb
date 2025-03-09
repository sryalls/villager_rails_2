class CreateResources < ActiveRecord::Migration[8.0]
  def change
    create_table :resources do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :resources, :name, unique: true
  end
end
