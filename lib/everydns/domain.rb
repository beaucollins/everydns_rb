module EveryDNS
  
  PRIMARY_REGEX = /<a href="(\.\/)?dns\.php\?action=editDomain&did=([\d]+)"[^>]*>([^<]+)<\/a>/
  SECONDARY_REGEX = /<font[^>]*>[\d]+\.([^ ]+) <b>\(<\/b>([^<]+)<b>\)<\/b> \[[^\]]+\][^\[]+\[<a href="[^"]+did=([\d]+)&t=sec">[^\]]+\]/
  DYNAMIC_REGEX = /<a href='(\.\/)?dns\.php\?action=editDynamic&dynid=([\d]+)'[^>]*>([^<]+)<\/a>/
  WEBHOP_REGEX = /^(.*) -> <input type=?"text" value="([^"]+)"(.*)\[<a href="\.\/dns\.php\?action=delDomain&did=([\d]+)"/
  
  class Domain
  
    # Parses some nasty html with a regex and returns an array of Domain objects
    def self.parse_list(string)
      domains = string.scan(PRIMARY_REGEX).inject([]) { |collector, matches|
        collector << self.new(matches[2], matches[1])
      }
      domains = string.scan(SECONDARY_REGEX).inject(domains) { |collector, matches|
        collector << self.new(matches[0].strip, matches[2], :secondary, matches[1].strip )
      }
      domains = string.scan(DYNAMIC_REGEX).inject(domains) { |collector, matches| 
        collector << self.new(matches[2], matches[1], :dynamic)
      }
      string.scan(WEBHOP_REGEX).inject(domains) { |collector, matches|
        collector << self.new(matches[0], matches.last, :webhop, matches[1])
      }
    end
  
    attr_accessor :host, :id, :type, :option
  
    VALID_TYPES = [:primary, :secondary, :dynamic, :webhop]
  
    def initialize(host, id=nil, type = :primary, option=nil)
      @host, @id = host, id
      @type = type.to_sym
      @option = option
      raise ArgumentError, "type must be one of: #{VALID_TYPES.join(', ')}" unless VALID_TYPES.include?(@type)
      raise ArgumentError, "option must be set if type is :secondary or :webhop" if (@option.nil? || @option.empty?) && [:webhop, :secondary].include?(@type)
    end
  
    VALID_TYPES.each do |type|
      define_method("#{type}?") { @type == type }
    end
  
    def new?
      id.nil?
    end
  
    def to_s
      self.host
    end
  
    def create_options
      options = {'newdomain' => self.host }
      options.merge!({'sec' => self.type_code }) unless self.primary?
      options.merge!({'ns' => self.option}) if self.secondary?
      options.merge!({'hop' => self.option}) if self.webhop?
      options
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