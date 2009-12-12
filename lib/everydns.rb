# Manage EveryDNS domains and dns records through a ruby api by pretending
# to be a user using the browser
require 'everydns/domain'
require 'everydns/client'

module EveryDNS
  
  EVERYDNS_HOSTNAME = 'www.everydns.com'
  HTTP_USER_AGENT = 'RbEveryDNS'
  SESSION_TIMEOUT = 10 *60
    
end

require 'uri'

class String
  def to_query_string(scope='')
    URI.escape(scope.empty? ? self.to_s : "#{scope}=#{self.to_s}")
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
