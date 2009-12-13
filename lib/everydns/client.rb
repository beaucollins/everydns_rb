require 'everydns/cookies'
module EveryDNS

  class LoginFailed < StandardError; end;
  
  RESPONSE_MESSAGES = {
    :LOGIN_FAILED => 'Login failed, try again!',
    :DOMAIN_ADDED_PRIMARY => '%s has been added to the database.',
    :DOMAIN_ADDED_DYNAMIC => '%s has been added to the database as dynamic.',
    :DOMAIN_ADDED_SECONDARY => '%s has been added to the database as secondary with \'%s\' as nameserver.',
    :DOMAIN_ADDED_WEBHOP => '%s has been added to the database as webhop.',
    :DOMAIN_DELETED => 'Domain %s has been deleted.',
    :DOMAIN_EXISTS => '%s already exists in database.'
  }
  
  # The main interface for managing EveryDNS domains. Provide your
  # username and password to the client then perform desired rquests.
  class Client
    require 'base64'
    require 'net/http'
    require 'uri'
    
    attr_reader :username, :password, :request_count
    
    def initialize(username, password)
      @username = username
      @password = password
      @last_login = nil
      @domain_list = nil
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
      response = post '/account.php', {
        'action' => 'login',
        'username' => @username,
        'password' => @password
      }
      if response_status_message(response) != RESPONSE_MESSAGES[:LOGIN_FAILED]
        @last_login = Time.now
        @authenticated = true
        return @last_login
      else
        @last_login = nil
        @authenticated = false
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
    
    # Returns an EveryDNS::DomainList
    def list_domains
      login!
      res = get('/manage.php')
      @domain_list = DomainList.parse_list(res.body)
    end
    
    # Add a host as a domain managed by EveryDNS. Options:
    #   *:secondary
    #   *:dynamic
    #   *:webhop
    def add_domain(host, type = :primary, option=nil)
      login!
      domain = Domain.new(host, nil, type, option)
      res = post '/dns.php', {
        'action' => 'addDomain'
      }.merge(domain.create_options)
      if response_status_message(res) == (RESPONSE_MESSAGES["DOMAIN_ADDED_#{type}".upcase.intern] % [host, option])
        list_domains
        return true
      else
        puts response_status_message(res)
        return false
      end
    end
    
    def remove_domain(host)
      login!
      domain = @domain_list[host]
      res = post '/dns.php', {
        'action' => 'confDomain'
      }.merge(domain.delete_options)
      if response_status_message(res) == (RESPONSE_MESSAGES[:DOMAIN_DELETED] % host)
        list_domains
        return true
      else
        return false
      end
    end
    
    def domains
      @domain_list ||= DomainList.new
    end
    
    def response_status_message(http_response)
      return false unless http_response.is_a?(Net::HTTPRedirection)
      query = URI.parse(http_response['location']).query
      return false if query.nil?
      msg = Base64.decode64(query.decode_query_string['msg'])
      return msg
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