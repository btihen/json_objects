class CreatePlants < ActiveRecord::Migration[5.0]
  def change
    create_table :plants do |t|
      t.string :specie,   null: false
      t.integer :quantity
      t.decimal :area_m2

      t.timestamps
    end
  end
end
