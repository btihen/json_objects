class Building < ApplicationRecord
  # https://evilmartians.com/chronicles/wrapping-json-based-active-record-attributes-with-classes
  # http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns

  # DB jsonb - simple object
  attribute :location,  AddressType.new
  # DB jsonb object with addresses as sub-objects
  attribute :owner,     OwnerType.new
  # DB jsonb simple array of objects
  attribute :rooms,     RoomsType.new
  # Virtual Attribute (not persisted)
  attribute :temp_info, :string

end
