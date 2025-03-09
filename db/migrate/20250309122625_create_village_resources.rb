class CreateVillageResources < ActiveRecord::Migration[8.0]
  def change
    create_table :village_resources do |t|
      t.references :village, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.integer :count

      t.timestamps
    end
  end
end
