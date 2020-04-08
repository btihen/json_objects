# https://evilmartians.com/chronicles/wrapping-json-based-active-record-attributes-with-classes

class GardenOwnerType < ActiveModel::Type::Value

  # http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns
  # include ActiveModel::Type::Helpers::Mutable

  def type
    :json
  end

  def cast_value(value)
    case value
    when String  # comes from DB as a string
      decoded = ActiveSupport::JSON.decode(value) rescue nil
      if decoded.nil?
        Owner.new
      else
        addresses_list = decoded["addresses"] || []
        addresses  = addresses_list.map{|attribs| Address.new(attribs)}
        owner_hash = decoded.except("addresses")
        owner     = Owner.new(owner_hash || {})
        owner.addresses << addresses unless addresses.blank?
        owner
      end
    when Hash
      addresses = value["addresses"].map{|attribs| Address.new(attribs)}
      owner     = Owner.new(value.except("addresses") || {})
      owner.addresses << addresses  unless addresses.blank?
      owner
    when Owner  # assignments can use a model
      value
    end
  end

  def serialize(value)
    case value
    when Hash
      ActiveSupport::JSON.encode(value)
    when Owner
      if value.attributes.all?{ |_attrib, data| data.nil? }
        ActiveSupport::JSON.encode({})
      else
        value_hash = value.attributes.except("id", "created_at", "updated_at")
        addresses  = value.addresses.map { |address| address.attributes }
        value_hash["addresses"] = addresses
        ActiveSupport::JSON.encode(value_hash || {})
      end
    else
      super
    end
  end

  def changed_in_place?(raw_old_value, new_value)
    cast_value(raw_old_value) != new_value
  end

  # http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns
  # def accessor
  #   ActiveRecord::Store::StringKeyedHashAccessor
  # end

end
