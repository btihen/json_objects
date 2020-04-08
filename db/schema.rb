# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200408152500) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string   "address_name"
    t.string   "street"
    t.string   "town"
    t.string   "postcode"
    t.integer  "owner_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["owner_id"], name: "index_addresses_on_owner_id", using: :btree
  end

  create_table "buildings", force: :cascade do |t|
    t.jsonb    "location",   default: {}, null: false
    t.jsonb    "owner",      default: {}, null: false
    t.jsonb    "rooms",      default: [], null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["location"], name: "index_buildings_on_location", using: :gin
    t.index ["owner"], name: "index_buildings_on_owner", using: :gin
    t.index ["rooms"], name: "index_buildings_on_rooms", using: :gin
  end

  create_table "gardens", force: :cascade do |t|
    t.string   "garden_name",                  null: false
    t.json     "garden_locale", default: "{}", null: false
    t.json     "garden_owner",  default: "{}", null: false
    t.json     "plants",        default: "[]", null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "owners", force: :cascade do |t|
    t.string   "full_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plants", force: :cascade do |t|
    t.string   "specie",     null: false
    t.integer  "quantity"
    t.decimal  "area_m2"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.string   "usage",      null: false
    t.decimal  "area_m2"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "addresses", "owners"
end
