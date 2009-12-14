module EveryDNS
  
  class Record
    
    VALID_TYPES = [:A, :CNAME, :NS, :MX, :TXT, :AAAA]
    TYPE_NUMBERS = {
      :A      => 1,
      :CNAME  => 2,
      :NS     => 3,
      :MX     => 4,
      :TXT    => 5,
      :AAAA   => 7
    }
    
    attr_reader :host, :type, :mx, :ttl, :id
    
    def initialize(domain, host, type, value, mx='', ttl=7200, rid=nil)
      raise ArgumentError, "domain must be an instance of EveryDNS::Domain" unless domain.is_a? EveryDNS::Domain
      @host = host
      @type = type.intern
      @mx = mx
      @ttl = ttl
      @id = rid
      raise ArgumentError, "Invalid type \"#{type}\", valid types are #{VALID_TYPES.join(', ')}" unless VALID_TYPES.include?(@type)
      raise ArgumentError, "Records of type \"#{type}\" must provide and mx value" if @type == :MX && @mx.empty?
    end
    
    VALID_TYPES.each do |type|
      define_method "#{type}_record?".downcase do
        @type == type
      end
    end
    
  end
  
end