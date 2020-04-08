module OwnerCoder
  extend self

  def load(data)case value
    when String
      decoded = ActiveSupport::JSON.decode(value) rescue nil
      Owner.new(decoded) unless decoded.nil?
    when Hash
      Owner.new(value)
    when Owner
      value
    end
  end

  def dump(data)
    case data
    when Hash
      ActiveSupport::JSON.encode(data)
    when Address
      addresses = data.addresses
      ActiveSupport::JSON.encode(data)
    else
      super
    end
  end

end
