class GardenAddressType < ActiveModel::Type::Value

  # http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns
  # include ActiveModel::Type::Helpers::Mutable

  def type
    :json
  end

  def cast_value(value)
    case value
    when String
      decoded = ActiveSupport::JSON.decode(value || {})
      Address.new(decoded || {})
    when Hash
      Address.new(value || {})
    when Address
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

  # http://til.obiefernandez.com/posts/8c31a92080-rails-5-attributes-api-jsonb-postgres-columns
  # def accessor
  #   ActiveRecord::Store::StringKeyedHashAccessor
  # end

end
