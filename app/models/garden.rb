class Garden < ApplicationRecord

  # DB jsonb - simple object
  attribute :garden_locale,  GardenAddressType.new
  # DB jsonb object with addresses as sub-objects
  attribute :garden_owner,   GardenOwnerType.new
  # DB jsonb simple array of objects
  attribute :rooms,          GardenPlantType.new

end
