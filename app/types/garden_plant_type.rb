class GardenPlantType < ActiveModel::Type::Value

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
        [Plant.new]
      elsif decoded.is_a? Array
        decoded.map { |attribs| Plant.new(attribs) }
      elsif decoded.is_a? Hash
        [Plant.new(decoded)]
      end
    when Hash
      [Plant.new(value || {})]
    when Plant
      [value]
    when Array
      value
    else
      raise ArgumentError, "invalid input"
    end
  end

  def serialize(value)
    case value
    when Hash
      save_hash = value.reject { |_attr, val| val.blank? }
      ActiveSupport::JSON.encode([save_hash] || [])
    when Array
      if value.blank?
        ActiveSupport::JSON.encode([])
      elsif value.first.is_a? Plant
        # if storing blank values is wanted then:
        # value_map = value.map{ |plant| plant.attributes }.reject { |plant| plant.blank? }
        # or if just some values should be removed
        # value_map = value.map{ |plant| plant.attributes.except("id", "created_at", "updated_at") }.reject { |plant| plant.blank? }
        # or remove all unused values (they will be resored with cast_value)
        value_map = value.map{ |plant| plant.attributes.reject {|_attr, val| val.blank?} }
                        .reject { |plant| plant.blank? }
        ActiveSupport::JSON.encode(value_map || [])
      elsif value.first.is_a? Hash
        value_map = value.map { |plant| plant.reject {|_attr, val| val.blank?} }
                          .reject { |plant| plant.blank? }
        ActiveSupport::JSON.encode(value_map || [])
      else
        raise ArgumentError, "invalid input"
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
