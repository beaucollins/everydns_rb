require 'everydns/cookies'
module EveryDNS

  class LoginFailed < StandardError; end;
  
  # The main interface for managing EveryDNS domains. Provide your
  # username and password to the client then perform desired rquests.
  class Client
    
    require 'net/http'
    require 'uri'
    
    attr_reader :username, :password, :request_count
    
    def initialize(username, password)
      @username = username
      @password = password
      @last_login = nil
      @domains = nil
      @records = nil
      @request_count = 0
      @http_client
      @cookie_store = Cookies::Store.new
    end
    
    # Send username/password as post data to correct url and parse
    # response for success string. Stores the PHP session cookie so
    # subsequent requests do not need to be logged in
    def login
      return @last_login if !@last_login.nil? && @last_login < @last_login + SESSION_TIMEOUT
      res = post '/account.php', {
        'action' => 'login',
        'username' => @username,
        'password' => @password
      }
      res = get(URI.join("http://#{EVERYDNS_HOSTNAME}", '/account.php', res['location']).to_s)
      if res.body =~ %r{Status: <b>Logged in</b> -- Welcome to Everydns.net}
        @last_login = Time.now
        @authenticated = true
        return @last_login
      else
        @authenticated = false
        return false
      end
    end
    
    def login!
      raise LoginFailed, 'Could not login with provided username and password' if !self.login
      return @last_login
    end
    
    # If the current session has logged in successfully yet
    def authenticated?
      @authenticated
    end
    
    # Returns an array of EveryDNS::Domain objects
    def list_domains
      login!
      res = get '/manage.php'
      Domain.parse_list(res.body)
    end
    
    # Add a host as a domain managed by EveryDNS. Options:
    #   *:secondary
    #   *:dynamic
    #   *:webhop
    def add_domain(host, type = :primary, option=nil)
            
      domain = Domain.new(host, nil, type, option)
      self.post '/dns.php', {
        'action' => 'addDomain'
      }.merge(domain.create_options)
      
    end
    
    private
    
      def post path, data
        @request_count += 1
        update_cookies(http_client.post(path, data.to_query_string, prepare_headers))
      end
      
      def get path, data=nil
        @request_count += 1
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
  
end