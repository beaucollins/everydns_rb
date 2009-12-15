module EveryDNS
  
  class Record
    
    VALID_TYPES = [:A, :CNAME, :NS, :MX, :TXT, :AAAA]
    TYPE_NUMBERS = {
      :A      => '1',
      :CNAME  => '2',
      :NS     => '3',
      :MX     => '4',
      :TXT    => '5',
      :AAAA   => '7'
    }
    
    attr_reader :domain, :host, :type, :value, :mx, :ttl, :id
    
    def initialize(domain, host, type, value, mx='', ttl=7200, rid=nil)
      raise ArgumentError, "domain must be an instance of EveryDNS::Domain" unless domain.is_a? EveryDNS::Domain
      @domain = domain
      @host = host
      @value = value
      @type = type.to_s.upcase.intern
      @mx = mx
      @ttl = ttl
      @id = rid.to_i
      raise ArgumentError, "Invalid type \"#{type}\", valid types are #{VALID_TYPES.join(', ')}" unless VALID_TYPES.include?(@type)
      raise ArgumentError, "Records of type \"#{type}\" must provide and mx value" if @type == :MX && @mx.empty?
    end
    
    def new?
      id.nil? || id == 0
    end
    
    def inspect
      '<%s:%i %s %s (%s)>' % [self.class, object_id, self.host, self.type, self.id]
    end
    
    VALID_TYPES.each do |type|
      define_method "#{type}_record?".downcase do
        @type == type
      end
    end
    
    def create_options
      {
        'action' => "add#{"Dynamic" if domain.dynamic?}Record",
        'domain' => domain.host,
        'field1' => self.host,
        'type' => TYPE_NUMBERS[self.type],
        'field2' => self.value,
        'mxVal' => self.mx,
        'ttl' => self.ttl.to_s
      }.merge({
        (domain.primary? ? 'did' : 'dynid') => domain.id.to_s
      })
    end
    
    def delete_options
      if domain.primary?
        {
          'action' => 'deleteRec',
          'rid' => self.id.to_s,
          'did' => domain.id.to_s,
          'domain' => domain.host_base64
        }
      else
        {
          'action' => 'deleteRec',
          'dynrid' => self.id.to_s,
          'dynid' => domain.id.to_s,
          'domain' => domain.host_base64
        }
      end
    end
    
  end
  
end