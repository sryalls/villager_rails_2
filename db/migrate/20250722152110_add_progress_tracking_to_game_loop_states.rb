class AddProgressTrackingToGameLoopStates < ActiveRecord::Migration[8.0]
  def change
    # Add progress tracking fields to store JSON data
    add_column :game_loop_states, :processed_villages, :text, comment: "JSON array of village IDs processed in this loop"
    add_column :game_loop_states, :processed_buildings, :text, comment: "JSON hash of village_id => [building_ids] processed"
  end
end
