class DropResourceProductionsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :resource_productions do |t|
      t.references :village, null: false, foreign_key: true
      t.references :building, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.integer :quantity_produced, null: false
      t.decimal :building_multiplier, precision: 5, scale: 2, default: 1.0
      t.datetime :produced_at, null: false
      t.string :loop_cycle_id
      t.timestamps

      t.index [ :village_id, :building_id, :resource_id, :produced_at ],
              name: "index_resource_productions_on_unique_production"
      t.index [ :village_id, :building_id, :produced_at ]
      t.index :loop_cycle_id
    end
  end
end
