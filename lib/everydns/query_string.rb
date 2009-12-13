class String
  def to_query_string(scope='')
    URI.escape(scope.empty? ? self.to_s : "#{scope}=#{self.to_s}")
  end
  
  # At this point very limited in it's ability
  def decode_query_string
    self.split("&").inject({}) { |collector, string|
      pair = string.split('=', 2)
      collector.merge({pair[0] => pair[1]})
    }
  end
  
end

class Array
  def to_query_string(scope='')
    self.collect { |item|
      item.to_query_string("#{scope}[]")
    }.join('&')
  end
end

class Hash
  def to_query_string(scope='')
    self.collect { |key, value|
      value.to_query_string(scope.empty? ? key : "#{scope}[#{key}]")
    }.join("&")
  end
end
