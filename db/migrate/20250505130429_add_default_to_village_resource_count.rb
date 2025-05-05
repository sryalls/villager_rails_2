class AddDefaultToVillageResourceCount < ActiveRecord::Migration[8.0]
  def change
    change_column_default :village_resources, :count, from: nil, to: 0
  end
end
