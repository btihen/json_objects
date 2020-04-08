class CreateGardens < ActiveRecord::Migration[5.0]
  def change
    create_table :gardens do |t|
      t.string :garden_name,   null: false
      t.json   :garden_locale, null: false, default: {}
      t.json   :garden_owner,  null: false, default: {}
      t.json   :plants,        null: false, default: []

      t.timestamps
    end
  end
end
