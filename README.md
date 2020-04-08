# README

Demo using Rails 5.0 (this should work equally well in Rails 6.x) with virtual attributes and json / jsonb columns to store / restore model
I have only found it practical to use attribute types to accomplish this

NOTE: some articles suggest it is needed to register the types (in: config/initializers/types.rb), but it seems to work without - at least in this case

## JSONB

### Examples

* building.location - is an example of a model stored as a jsonb column (with no associations)
* building.owner    - is an example of a model stored as a jsonb column (with a has_many association - of addresses)
* building.rooms    - is an example of an array of models stored in a jsonb column
* building.temp     - is an example of a virtual attribute (one that won't be persisted - stored in the DB)

### Usage

Setup
```
rails db:create
rails db:migrate
```

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

### Examples


* gardens.garden_locale - simple model
* gardens.garden_owner  - model with has_many
* gardens.plants        - array of plants


### Usage
