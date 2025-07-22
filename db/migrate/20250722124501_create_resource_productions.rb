class CreateResourceProductions < ActiveRecord::Migration[8.0]
  def change
    create_table :resource_productions do |t|
      t.references :village, null: false, foreign_key: true
      t.references :building, null: false, foreign_key: true  
      t.references :resource, null: false, foreign_key: true
      t.integer :quantity_produced, null: false
      t.integer :building_multiplier, default: 1
      t.datetime :produced_at, null: false
      t.string :loop_cycle_id # To group productions from same game cycle
      
      t.timestamps
    end
    
    # Prevent duplicate production within time windows
    add_index :resource_productions, 
              [:village_id, :building_id, :resource_id, :produced_at],
              name: "index_resource_productions_on_unique_production"
              
    # For efficient time-window queries
    add_index :resource_productions, [:village_id, :building_id, :produced_at]
    add_index :resource_productions, :loop_cycle_id
  end
end
