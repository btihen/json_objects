class Address < ApplicationRecord
  # relations
  belongs_to :owner, optional: true

  # DB Attributes
  # attribute :address_name :string (home, etc)
  # attribute :street,    :string
  # attribute :town,      :string
  # attribute :postcode,  :string
end
