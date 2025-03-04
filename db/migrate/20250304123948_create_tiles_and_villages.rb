class CreateTilesAndVillages < ActiveRecord::Migration[8.0]
  def change
    create_table :tiles do |t|
      t.integer :x
      t.integer :y

      t.timestamps
    end

    create_table :villages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tile, null: false, foreign_key: true

      t.timestamps
    end
  end
end
