class DropGameLoopStatesTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :game_loop_states if table_exists?(:game_loop_states)
  end

  def down
    # We can't easily recreate the table since we're moving to Redis
    # If you need to rollback, you'll need to manually recreate the table structure
    raise ActiveRecord::IrreversibleMigration, "Cannot recreate game_loop_states table - data moved to Redis"
  end
end
