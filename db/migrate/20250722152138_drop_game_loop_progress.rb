class DropGameLoopProgress < ActiveRecord::Migration[8.0]
  def change
    drop_table :game_loop_progresses do |t|
      t.string :loop_cycle_id, null: false
      t.string :progress_type, null: false
      t.references :village, null: true, foreign_key: true
      t.references :building, null: true, foreign_key: true
      t.datetime :completed_at, null: false

      t.timestamps
    end
  end
end
