class Building < ApplicationRecord
  # https://evilmartians.com/chronicles/wrapping-json-based-active-record-attributes-with-classes
  # DB jsonb - simple object
  attribute :location,  AddressType.new

  # DB jsonb object with addresses as sub-objects
  attribute :owner,     OwnerType.new

  # DB jsonb simple array of objects
  attribute :rooms,     RoomsType.new

  # http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns
end
