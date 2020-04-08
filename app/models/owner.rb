class Owner < ApplicationRecord
  # relations
  has_many :addresses

  # virutual attribute (not in DB persisted)
  attribute :nickname, :string
end
