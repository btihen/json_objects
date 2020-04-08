# https://evilmartians.com/chronicles/wrapping-json-based-active-record-attributes-with-classes
class OwnerType < ActiveModel::Type::Value

  # http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns
  # include ActiveModel::Type::Helpers::Mutable

  def type
    :jsonb
  end

  def cast_value(value)
    case value
    when String  # comes from DB as a string
      decoded = ActiveSupport::JSON.decode(value) rescue nil
      if decoded.blank?
        Owner.new
      else
        addresses_list = decoded["addresses"] || []
        addresses  = addresses_list.map{|attribs| Address.new(attribs)}
        owner_hash = decoded.except("addresses")
        owner      = Owner.new(owner_hash || {})
        owner.addresses << addresses unless addresses.blank?
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
      save_hash = value.reject { |_attr, val| val.blank? }
      ActiveSupport::JSON.encode(save_hash || {})
    when Owner
      save_hash = value.attributes.reject { |_attr, val| val.blank? }
      addresses = value.addresses
                        .map { |address| address.attributes.reject { |_attr, val| val.blank? } }
                        .reject{|addr| addr.blank?}
      save_hash["addresses"] = addresses  unless addresses.blank?
      ActiveSupport::JSON.encode(save_hash || {})
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
