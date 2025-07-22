class DropVillageLoopFailuresTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :village_loop_failures do |t|
      t.bigint :village_id, null: false
      t.string :loop_cycle_id
      t.text :error_message
      t.datetime :failed_at, null: false
      t.boolean :recovered, default: false
      t.datetime :recovered_at
      t.timestamps

      t.index :loop_cycle_id
      t.index [ :recovered, :failed_at ]
      t.index [ :village_id, :failed_at ]
      t.index :village_id
    end
  end
end
