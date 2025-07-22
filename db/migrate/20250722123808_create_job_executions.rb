class CreateJobExecutions < ActiveRecord::Migration[8.0]
  def change
    create_table :job_executions do |t|
      t.string :job_id, null: false
      t.string :job_type, null: false
      t.datetime :executed_at, null: false
      t.text :resource_snapshot
      t.references :village, null: true, foreign_key: true
      t.references :building, null: true, foreign_key: true
      t.integer :multiplier, default: 1
      t.string :status, default: 'completed'

      t.timestamps
    end

    add_index :job_executions, [ :job_id, :job_type ], unique: true
    add_index :job_executions, [ :village_id, :executed_at ]
    add_index :job_executions, [ :building_id, :executed_at ]
    add_index :job_executions, :status
  end
end
