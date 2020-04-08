class CreateRooms < ActiveRecord::Migration[5.0]
  def change
    create_table :rooms do |t|
      t.string  :usage,  null: false
      t.decimal :area_m2

      t.timestamps
    end
  end
end
