# Manage EveryDNS domains and dns records through a ruby api by pretending
# to be a user using the browser
require 'everydns/domain_list'
require 'everydns/domain'
require 'everydns/record_list'
require 'everydns/record'
require 'everydns/client'
require 'everydns/query_string'

module EveryDNS
  
  EVERYDNS_HOSTNAME = 'www.everydns.com'
  HTTP_USER_AGENT = 'RbEveryDNS'
  SESSION_TIMEOUT = 10 *60
    
end

require 'uri'

