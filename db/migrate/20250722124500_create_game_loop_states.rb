class CreateGameLoopStates < ActiveRecord::Migration[8.0]
  def change
    create_table :game_loop_states do |t|
      t.string :loop_type, null: false # 'play_loop', 'village_loop', etc.
      t.string :identifier # village_id for village loops, nil for global play loop
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.string :status, default: 'running' # 'running', 'completed', 'failed'
      t.text :error_message
      t.string :sidekiq_job_id

      t.timestamps
    end

    # Ensure only one active loop of each type at a time
    add_index :game_loop_states, [ :loop_type, :identifier, :status ],
              unique: true,
              where: "status = 'running'",
              name: "index_game_loop_states_on_active_loops"

    add_index :game_loop_states, [ :loop_type, :identifier, :started_at ]
    add_index :game_loop_states, :status
  end
end
