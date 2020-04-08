class CreateAddresses < ActiveRecord::Migration[5.0]
  def change
    create_table :addresses do |t|
      t.string :address_name
      t.string :street
      t.string :town
      t.string :postcode
      t.belongs_to :owner, foreign_key: true

      t.timestamps
    end
  end
end
