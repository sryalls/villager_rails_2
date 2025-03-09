class CreateJoinTableResourceTag < ActiveRecord::Migration[8.0]
  def change
    create_join_table :resources, :tags do |t|
      t.index :resource_id
      t.index :tag_id
    end
  end
end
