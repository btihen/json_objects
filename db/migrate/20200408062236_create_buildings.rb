class CreateBuildings < ActiveRecord::Migration[5.0]
  def change
    create_table :buildings do |t|
      t.jsonb :location,  null: false, default: {}
      t.jsonb :owner,     null: false, default: {}
      t.jsonb :rooms,     null: false, default: []

      t.timestamps
    end
    add_index  :buildings, :location, using: :gin
    add_index  :buildings, :owner,    using: :gin
    add_index  :buildings, :rooms,    using: :gin
  end
end
