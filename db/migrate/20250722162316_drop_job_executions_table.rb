class DropJobExecutionsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :job_executions do |t|
      t.string :job_id, null: false
      t.string :job_type, null: false
      t.datetime :executed_at, null: false
      t.string :status, null: false, default: 'completed'
      t.text :error_message
      t.text :resource_snapshot
      t.references :village, null: true, foreign_key: true
      t.references :building, null: true, foreign_key: true
      t.timestamps

      t.index [:job_id, :job_type], unique: true
      t.index :job_type
      t.index :executed_at
    end
  end
end
