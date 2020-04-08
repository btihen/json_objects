# README

Demo using Rails 5.0 (this should work equally well in Rails 6.x) with virtual attributes and json / jsonb columns to store / restore model
I have only found it practical to use attribute types to accomplish this

NOTE: some articles suggest it is needed to register the types (in: config/initializers/types.rb), but it seems to work without - at least in this case

## Source Code

https://github.com/btihen/json_objects

## Setup Example

```
git clone https://github.com/btihen/json_objects.git
cd json_objects
bundle
rails db:create
rails db:migrate
```

## Resources

* don't use serialize anymore with jsonb - https://stackoverflow.com/questions/54124358/using-array-in-rails-jsonb-column

* jsonb columns wrapped into classes -  https://evilmartians.com/chronicles/wrapping-json-based-active-record-attributes-with-classes

* NO LONGER USE DEFAULT STRING VALUES FOR JSON/JSONB columns - http://til.obiefernandez.com/posts/2fd6272c8f-set-defaults-for-jsonb-postgres-columns-in-rails
```
# DO THIS
t.jsonb :preferences, default: {}, null: false

# NO longer works
t.jsonb :preferences, default: '{}', null: false
```
* Types need to be registered if using the column type :jsonb - http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns (also shows usage with OJ - much FASTER)
```
# config/initializer/types.rb
ActiveRecord::Type.register(:jsonb, JsonbType, override: true)

# use like>
class User < ApplicationRecord
  attribute :preferences, :jsonb, default: {}
```

* rails 5 way with storage coder (alternative DB override - but no hooks for models)
https://books.google.ch/books?id=YGQ-DwAAQBAJ&pg=PT359&lpg=PT359&dq=rails+store+coder&source=bl&ots=SrdfWFeEpI&sig=ACfU3U21J29Roog5sfCnRsXzmH7ffnrAgQ&hl=en&sa=X&ved=2ahUKEwi72r-ypdjoAhWDyKQKHTiKDDgQ6AEwB3oECAsQKQ#v=onepage&q=rails%20store%20coder&f=false


## JSONB

slower to save, faster to search & retieve

### Examples

* building.location - is an example of a model stored as a jsonb column (with no associations)
* building.owner    - is an example of a model stored as a jsonb column (with a has_many association - of addresses)
* building.rooms    - is an example of an array of models stored in a jsonb column
* building.temp     - is an example of a virtual attribute (one that won't be persisted - stored in the DB)

### Code

Model with Jsonb columns
```
class CreateBuildings < ActiveRecord::Migration[5.0]
  def change
    create_table :buildings do |t|
      t.jsonb :location,  null: false, default: {}  # {} for single models / do not use '{}'
      t.jsonb :owner,     null: false, default: {}
      t.jsonb :rooms,     null: false, default: []  # [] for array of models / do not use '[]'

      t.timestamps
    end
    add_index  :buildings, :location, using: :gin
    add_index  :buildings, :owner,    using: :gin
    add_index  :buildings, :rooms,    using: :gin
  end
end
```

Model with JSONB columns to expand into a model
```
# app/models/buildings.rb
class Building < ApplicationRecord
  # https://evilmartians.com/chronicles/wrapping-json-based-active-record-attributes-with-classes

  # DB jsonb - simple object
  attribute :location,  AddressType.new

  # DB jsonb object with addresses as sub-objects
  attribute :owner,     OwnerType.new

  # DB jsonb simple array of objects
  attribute :rooms,     RoomsType.new

  # Virtual Attribute (not persisted)
  attribute :temp_info, :string
end
```

Sample (simples Type)
```
class AddressType < ActiveModel::Type::Value

  def type
    :jsonb
  end

  def cast_value(value)
    case value
    when String
      decoded = ActiveSupport::JSON.decode(value) rescue nil
      Address.new(decoded) unless decoded.nil?
    when Hash
      Address.new(value)
    when Address
      value
    else
      raise ArgumentError, "Invalid Input"
    end
  end

  def serialize(value)
    case value
    when Hash
      # remove empty attributes / casting restores them
      save_hash = value.reject { |_attr, val| val.blank? }
      ActiveSupport::JSON.encode(save_hash || {})
    when Address
      save_hash = value.attributes.reject { |_attr, val| val.blank? }
      ActiveSupport::JSON.encode(save_hash || {})
    else
      super
    end
  end

  def changed_in_place?(raw_old_value, new_value)
    cast_value(raw_old_value) != new_value
  end
end
```

Nore complex with submodel (has_many) addresses
```
class OwnerType < ActiveModel::Type::Value

  def type
    :jsonb
  end

  def cast_value(value)
    case value

    # comes from DB as a string
    when String
      decoded = ActiveSupport::JSON.decode(value) rescue nil
      if decoded.blank?
        Owner.new

      else
        # restore main object without related (has_many) hash
        owner_hash = decoded.except("addresses")
        owner      = Owner.new(owner_hash || {})

        # extract the related address models (if there are none use [] an empty array)
        addresses_list = decoded["addresses"] || []
        # create/restore an array of restored addresses
        addresses  = addresses_list.map{|attribs| Address.new(attribs)}

        # associate related addresses if present
        owner.addresses << addresses unless addresses.blank?

        # return the fully restored address onject
        owner
      end

    when Hash
      addresses  = value["addresses"].map{|attribs| Address.new(attribs)}
      owner_hash = value.except("addresses")
      owner      = Owner.new(owner_hash || {})
      owner.addresses << addresses  unless addresses.blank?
      owner

    when Owner  # assignments using the model
      value

    else
      raise ArgumentError, "Invalid Input"
    end
  end

  def serialize(value)
    case value

    when Hash
      # remove empty attributes
      save_hash = value.reject { |_attr, val| val.blank? }
      # convert hash to json
      ActiveSupport::JSON.encode(save_hash || {})

    when Owner
      # convert object into hash & remove empty attributes
      save_hash = value.attributes.reject { |_attr, val| val.blank? }

      # extract related addresses, remove empty attributes & remove empty models
      addresses = value.addresses
                        .map { |address| address.attributes.reject { |_attr, val| val.blank? } }
                        .reject{|addr| addr.blank?}

      # add addresses as an array of hashes
      save_hash["addresses"] = addresses  unless addresses.blank?

      # convert hash to json
      ActiveSupport::JSON.encode(save_hash || {})

    else
      super
    end
  end

  def changed_in_place?(raw_old_value, new_value)
    cast_value(raw_old_value) != new_value
  end
end
```

### Usage

Open Rails Console and Rails DB
```
# console
$ rails c (prompt is >)
> work = Building.new
> work.attributes
=> {"id"=>nil,
    "location"=>#<Address:0x00007fa4ae8160c8 id: nil, address_name: nil, street: nil, town: nil, postcode: nil, owner_id: nil, created_at: nil, updated_at: nil>,
    "owner"=>#<Owner:0x00007fa4a9ec6490 id: nil, full_name: nil, created_at: nil, updated_at: nil>,
    "rooms"=>[],
    "created_at"=>nil,
    "updated_at"=>nil,
    "temp"=>nil}

# save and it should be stored without extra info
> work.save

# in DB console (prompt is #)
$ rails db
# \x
=# select * from buildings;
-[ RECORD 1 ]------------------------------------------------------------------------------------------
id         | 1
location   | {}
owner      | {}
rooms      | []
created_at | 2020-04-08 17:32:26.286446
updated_at | 2020-04-08 17:32:26.286446

# Assign virtual attribute info
> work.temp_info = "Hi"

# assign an address to location
> work.location = Address.new(street: "Gartenstr 3/4", town: "Bern")
> work.attributes
=> {"id"=>nil,
    "location"=>#<Address:0x00007fa4ae8c2350 id: nil, address_name: nil, street: "Gartenstr 3/4", town: "Bern", postcode: nil, owner_id: nil, created_at: nil, updated_at: nil>,
    "owner"=>#<Owner:0x00007fa4a8a55fb0 id: nil, full_name: nil, created_at: nil, updated_at: nil>,
    "rooms"=>[],
    "created_at"=>nil,
    "updated_at"=>nil,
    "temp_info"=>"Hi"}
> work.save

# in DB Console (notice all the attributes with nil are removed to save storage space)
# select * from buildings;
-[ RECORD 1 ] ------------------------------------------------------------------------------------
id         | 1
location   | {"town": "Bern", "street": "Gartenstr 3/4"}
owner      | {}
rooms      | []
created_at | 2020-04-08 17:32:26.286446
updated_at | 2020-04-08 17:37:55.307519


# create an owner (notice temp info is still loaded until work.reload - but is never stored in DB)
work.owner = Owner.new(full_name: "Garaio RE")
work.attributes
=> {"id"=>3,
    "location"=>#<Address:0x00007fa4aab69af8 id: nil, address_name: nil, street: "Gartenstr 3/4", town: "Bern", postcode: nil, owner_id: nil, created_at: nil, updated_at: nil>,
    "owner"=>#<Owner:0x00007fa4a8990350 id: nil, full_name: "Garaio RE", created_at: nil, updated_at: nil>,
    "rooms"=>[],
    "created_at"=>Wed, 08 Apr 2020 17:32:26 UTC +00:00,
    "updated_at"=>Wed, 08 Apr 2020 17:37:55 UTC +00:00,
    "temp_info"=>"Hi"}

# lets save again
work.save

# and check the DB
-[ RECORD 1 ]---------------------------------------------------------------------------------------------
id         | 1
location   | {"town": "Bern", "street": "Gartenstr 3/4"}
owner      | {"full_name": "Garaio RE"}
rooms      | []
created_at | 2020-04-08 17:32:26.286446
updated_at | 2020-04-08 17:41:54.580854

# add some owner addresses
> work.owner.addresses << Address.new(address_name: "HQ", street: "Laupinstr 43", town: "Bern")
> work.owner.addresses << Address.new(address_name: "Main Office", street: "Gartenstr 4", town: "Bern")
# add an empty model (we won't save it)
> work.owner.addresses << Address.new

# we can't directly see nested objects
> work.owner
=> #<Owner:0x00007fa4ae9d5198 id: nil, full_name: "Garaio RE", created_at: nil, updated_at: nil>

# but the relationships are there
> work.owner.addresses
=> [#<Address:0x00007fa4a99667e8 id: nil, address_name: "HQ", street: "Laupinstr 43", town: "Bern", postcode: nil, owner_id: nil, created_at: nil, updated_at: nil>,
    #<Address:0x00007fa4a9955dd0 id: nil, address_name: "Main Office", street: "Gartenstr 4", town: "Bern", postcode: nil, owner_id: nil, created_at: nil, updated_at: nil>,
    #<Address:0x00007fa4a8a18d40 id: nil, address_name: nil, street: nil, town: nil, postcode: nil, owner_id: nil, created_at: nil, updated_at: nil>]

# when we look at the attributes we don't see the nested objects (either)
> work.attributes
=> {"id"=>3,
    "location"=>#<Address:0x00007fa4a8a01140 id: nil, address_name: nil, street: "Gartenstr 3/4", town: "Bern", postcode: nil, owner_id: nil, created_at: nil, updated_at: nil>,
    "owner"=>#<Owner:0x00007fa4ae9d5198 id: nil, full_name: "Garaio RE", created_at: nil, updated_at: nil>,
    "rooms"=>[],
    "created_at"=>Wed, 08 Apr 2020 17:32:26 UTC +00:00,
    "updated_at"=>Wed, 08 Apr 2020 17:41:54 UTC +00:00,
    "temp_info"=>"Hi"}

# when we save though we need to add them with our OwnerType
> work.save

# now in the DB we will see the addresses (minus the empty address):
# select * from buildings;
-[ RECORD 1 ]-------------------------------------------------------------------------------------------
id         | 1
location   | {"town": "Bern", "street": "Gartenstr 3/4"}
owner      | {"addresses": [{"town": "Bern", "street": "Laupinstr 43", "address_name": "HQ"}, {"town": "Bern", "street": "Gartenstr 4", "address_name": "Main Office"}], "full_name": "Garaio RE"}
rooms      | []
created_at | 2020-04-08 17:32:26.286446
updated_at | 2020-04-08 17:51:45.340493

# now lets test the json array of objects
> work.rooms = [Room.new(usage: "Meeting Room"), Room.new(usage: "Work Room")]
# and add an empty room too
> work.rooms << Room.new
> work.rooms
=> [#<Room:0x00007fa4a9ee5cc8 id: nil, usage: "Meeting Room", area_m2: nil, created_at: nil, updated_at: nil>,
    #<Room:0x00007fa4a9ee42b0 id: nil, usage: "Work Room", area_m2: nil, created_at: nil, updated_at: nil>]

# now see what save is like
work.save

# and what is in DB / notice the empty model is removed and only attributes with values are stored
# select * from buildings;
-[ RECORD 1 ]-----------------------------------------------------------------------------------------
id         | 1
location   | {"town": "Bern", "street": "Gartenstr 3/4"}
owner      | {"addresses": [{"town": "Bern", "street": "Laupinstr 43", "address_name": "HQ"}, {"town": "Bern", "street": "Gartenstr 4", "address_name": "Main Office"}], "full_name": "Garaio RE"}
rooms      | [{"usage": "Meeting Room"}, {"usage": "Work Room"}]
created_at | 2020-04-08 17:32:26.286446
updated_at | 2020-04-08 18:20:54.739895

# now lets be sure our Types restore the JSON in DB correctly
> work.reload
  Building Load (0.3ms)  SELECT  "buildings".* FROM "buildings" WHERE "buildings"."id" = $1 LIMIT $2  [["id", 1], ["LIMIT", 1]]
=> #<Building:0x00007fa4aab680b8
 id: 1,
 location:
  #<Address:0x00007fa4a9fbea50
   id: nil,
   address_name: nil,
   street: "Gartenstr 3/4",
   town: "Bern",
   postcode: nil,
   owner_id: nil,
   created_at: nil,
   updated_at: nil>,
 owner: #<Owner:0x00007fa4a9f56ec8 id: nil, full_name: "Garaio RE", created_at: nil, updated_at: nil>,
 rooms:
  [#<Room:0x00007fa4a9ee5cc8 id: nil, usage: "Meeting Room", area_m2: nil, created_at: nil, updated_at: nil>,
   #<Room:0x00007fa4a9ee42b0 id: nil, usage: "Work Room", area_m2: nil, created_at: nil, updated_at: nil>],
 created_at: Wed, 08 Apr 2020 17:32:26 UTC +00:00,
 updated_at: Wed, 08 Apr 2020 18:20:54 UTC +00:00>
```

## JSON

attributes not searchable within the db

### Examples

* gardens.garden_locale - simple model
* gardens.garden_owner  - model with has_many
* gardens.plants        - array of plants

### Usage

basically the same as jsonb
