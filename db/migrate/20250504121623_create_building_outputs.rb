class CreateBuildingOutputs < ActiveRecord::Migration[8.0]
  def change
    create_table :building_outputs do |t|
      t.references :building, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
