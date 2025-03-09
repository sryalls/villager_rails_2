class CreateVillageBuildings < ActiveRecord::Migration[8.0]
  def change
    create_table :village_buildings do |t|
      t.references :village, null: false, foreign_key: true
      t.references :building, null: false, foreign_key: true

      t.timestamps
    end
  end
end
