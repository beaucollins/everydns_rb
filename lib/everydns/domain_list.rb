require 'everydns/domain'

module EveryDNS
  
  DOMAIN_TYPES = [:primary, :secondary, :dynamic, :webhop]
  
  PRIMARY_REGEX = /<a href="(\.\/)?dns\.php\?action=editDomain&did=([\d]+)"[^>]*>([^<]+)<\/a>/
  SECONDARY_REGEX = /<font[^>]*>[\d]+\.([^ ]+) <b>\(<\/b>([^<]+)<b>\)<\/b> \[[^\]]+\][^\[]+\[<a href="[^"]+did=([\d]+)&t=sec">[^\]]+\]/
  DYNAMIC_REGEX = /<a href='(\.\/)?dns\.php\?action=editDynamic&dynid=([\d]+)'[^>]*>([^<]+)<\/a>/
  WEBHOP_REGEX = /^(.*) -> <input type=?"text" value="([^"]+)"(.*)\[<a href="\.\/dns\.php\?action=delDomain&did=([\d]+)"/
  
  # Represents the list of domains managed by a single EveryDNS account. Returned
  # by EveryDNS::Client#list_domains. Provides some convenience methods to filter
  # domains by type (primary, secondary, dynamic and webhop).
  class DomainList    
      
    attr_reader :domains
    
    # Given a string of HTML from EveryDNS parses out the list of domains and
    # necessary attributes to construct all of the EveryDNS::Domain objects
    def self.parse_list(html)
      list = self.new
      list.parse_list(html)
      list
    end
    
    def initialize()
      @domains = []
    end
    
    DOMAIN_TYPES.each do |type|
      define_method type do
        @domains.select {|domain| domain.type == type}
      end
    end
    
    include Enumerable
    def each
      @domains.each do |domain|
        yield domain
      end
    end
    
    def [](host)
      @domains.detect { |domain| domain.host == host  }
    end
    
    # Parses some nasty html with a regex and returns an array of Domain objects
    def parse_list(string)
      domains = string.scan(PRIMARY_REGEX).inject([]) { |collector, matches|
        collector << Domain.new(matches[2], matches[1])
      }
      domains = string.scan(SECONDARY_REGEX).inject(domains) { |collector, matches|
        collector << Domain.new(matches[0].strip, matches[2], :secondary, matches[1].strip )
      }
      domains = string.scan(DYNAMIC_REGEX).inject(domains) { |collector, matches| 
        collector << Domain.new(matches[2], matches[1], :dynamic)
      }
      domains = string.scan(WEBHOP_REGEX).inject(domains) { |collector, matches|
        collector << Domain.new(matches[0], matches.last, :webhop, matches[1])
      }
      @domains = domains
    end
    
  end
  
end