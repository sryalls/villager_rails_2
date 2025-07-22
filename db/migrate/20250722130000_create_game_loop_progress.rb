class CreateGameLoopProgress < ActiveRecord::Migration[8.0]
  def change
    create_table :game_loop_progresses do |t|
      t.string :loop_cycle_id, null: false
      t.string :progress_type, null: false # 'village_queued', 'building_processed', etc.
      t.references :village, null: true, foreign_key: true
      t.references :building, null: true, foreign_key: true
      t.datetime :completed_at, null: false
      
      t.timestamps
    end
    
    # Ensure we don't double-record the same progress
    add_index :game_loop_progresses, [:loop_cycle_id, :progress_type, :village_id, :building_id], 
              unique: true, 
              name: "index_game_loop_progresses_on_unique_progress"
              
    add_index :game_loop_progresses, :loop_cycle_id
  end
end
