module EveryDNS

  # An extremely basic cookie store used primarily to store the PHP session
  # used for authentication at everydns.com
  module Cookies
    
    class Store
      
      def initialize
        @cookies = {}
      end

      def each
        @cookies.each do |key, cookie|
          yield cookie
        end
      end
      
      def set_cookie(cookie_string)
        cookie = Cookie.parse(cookie_string)
        @cookies[cookie.name] = cookie
      end
      
      def to_s
        @cookies.inject([]){ |memo, pair| memo << pair.last.to_s }.join('; ')
      end
    end
    
    class Cookie
      
      attr_accessor :name, :value
      
      def initialize(name, value)
        @name = name
        @value = value
      end
      
      def self.parse(cookie_string)
        pair = cookie_string.split(';').first.strip.split('=', 2);
        self.new(pair.first, pair.last)
      end
            
      def to_s
        "#{@name}=#{@value}"
      end
      
    end
    
  end
  
end