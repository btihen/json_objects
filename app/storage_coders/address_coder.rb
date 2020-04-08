module AddressCoder
  extend self

  def load(data)case value
    when String
      decoded = ActiveSupport::JSON.decode(value) rescue nil
      Address.new(decoded) unless decoded.nil?
    when Hash
      Address.new(value)
    when Address
      value
    end
  end

  def dump(data)case data
    when Hash, Address
      ActiveSupport::JSON.encode(data)
    else
      super
    end
  end

end
