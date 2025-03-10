class CreateCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :costs do |t|
      t.references :building, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
