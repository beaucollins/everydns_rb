module EveryDNS
  require 'base64'
  class Domain
    
    attr_accessor :host, :id, :type, :option
    
    VALID_TYPES = [:primary, :secondary, :dynamic, :webhop]
    
    def initialize(host, id=nil, type = :primary, option=nil)
      @host, @id = host, id
      @type = type.to_sym
      @option = option
      raise ArgumentError, "type must be one of: #{VALID_TYPES.join(', ')}" unless VALID_TYPES.include?(@type)
      raise ArgumentError, "option must be set if type is :secondary or :webhop" if (@option.nil? || @option.empty?) && [:webhop, :secondary].include?(@type)
    end
    
    def host_base64
      base64.encode64 if self.host
    end
    
    VALID_TYPES.each do |type|
      define_method("#{type}?") { @type == type }
    end
    
    def can_have_records?
      [:primary, :dynamic].include? self.type
    end
    
    def new?
      id.nil?
    end
    
    def to_s
      self.host
    end
    
    def create_options
      options = {'action' => 'addDomain','newdomain' => self.host }
      options.merge!({'sec' => self.type_code }) unless self.primary?
      options.merge!({'ns' => self.option}) if self.secondary?
      options.merge!({'hop' => self.option}) if self.webhop?
      options
    end
    
    def delete_options
      {'action' => 'confDomain'}.merge({
        (self.dynamic? ? 'dynid' : 'deldid') => self.id
      })
    end
    
    def list_records_options
      if self.primary?
        {
          'action' => 'editDomain',
          'did' => self.id
        }
      else
        {
          'action' => 'editDynamic',
          'dynid' => self.id
        }
      end
    end
    
    def type_code
      {
        :primary => nil,
        :secondary => 'sec',
        :webhop=> 'webhop',
        :dynamic => 'dyn'
      }[@type]
    end
  
  end

end