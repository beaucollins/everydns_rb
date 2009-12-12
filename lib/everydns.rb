# Manage EveryDNS domains and dns records through a ruby api by pretending
# to be a user using the browser
module EveryDNS
  
  EVERYDNS_HOSTNAME = 'www.everydns.com'
  HTTP_USER_AGENT = 'RbEveryDNS'
  SESSION_TIMEOUT = 10 *60
  
  class LoginFailed < StandardError; end;
  
  # The main interface for managing EveryDNS domains. Provide your
  # username and password to the client then perform desired rquests.
  class Client
    
    require 'net/http'
    require 'uri'
    
    def initialize(username, password)
      @username = username
      @password = password
      @last_login = nil
      @domains = nil
      @records = nil
      @req_count = 0
      @http_client
      @cookie_store = Cookies::Store.new
    end
    
    # Send username/password as post data to correct url and parse
    # response for success string. Stores the PHP session cookie so
    # subsequent requests do not need to be logged in
    def login
      res = post '/account.php', "action=login&username=#{@username}&password=#{@password}"
      res = get(URI.join("http://#{EVERYDNS_HOSTNAME}", '/account.php', res['location']).to_s)
      if res.body =~ %r{Status: <b>Logged in</b> -- Welcome to Everydns.net}
        @authenticated = true
      else
        @authenticated = false
      end
      self.authenticated?
    end
    
    # If the current session has logged in successfully yet
    def authenticated?
      @authenticated
    end
    
    # Returns an array of EveryDNS::Domain objects
    def list_domains
      login
      res = get '/manage.php'
      Domain.parse_list(res.body)
    end
    
    # Add a host as a domain managed by EveryDNS. Options:
    #   *:secondary
    #   *:dynamic
    #   *:webhop
    def add_domain(host, options={})
      options = options.merge({
        :secondary => nil,
        :dynamic => false,
        :webhop => nil
      })
      
      post_data = {}
      
      domain = Domain.new(host, nil, options)
      self.post '/dns.php', {
        'action' => ''
      }.merge(domain.to_post_data)
      
    end
    
    private
    
      def post path, data
        update_cookies(http_client.post(path, data.to_query_string, prepare_headers))
      end
      
      def get path, data=nil
        update_cookies(http_client.get(path, prepare_headers))
      end
      
      def prepare_headers
        { 'cookie' => @cookie_store.to_s }
      end
      
      def update_cookies(response)
        @cookie_store.set_cookie(response['set-cookie']) unless response['set-cookie'].nil?
        response
      end
      
      def http_client
        return @http_client unless @http_client.nil?
        @http_client = Net::HTTP.new(EVERYDNS_HOSTNAME)
        @http_client
      end
    
  end
  
  class Domain
    
    # Parses some nasty html with a regex and returns an array of Domain objects
    def self.parse_list(string)
      string.scan(/<a href="\.\/dns.php\?action=editDomain&did=([\d]+)?"([^>]+)?>([^<]+)<\/a>/).collect do |matches|
        self.new(matches.last, matches.first)
      end
    end
    
    attr_accessor :host, :id
    
    def initialize(host, id, options={})
      @host, @id = host, id
    end
    
    def to_s
      self.host
    end
    
  end
  
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
        pair = cookie_string.split(';').first.strip.split('=');
        self.new(pair.first, pair.last)
      end
            
      def to_s
        "#{@name}=#{@value}"
      end
      
    end
    
  end
  
end

class String
  def to_query_string(scope='')
    "#{scope}=#{self.to_s}"
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
