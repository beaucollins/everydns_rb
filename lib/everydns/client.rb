require 'everydns/cookies'
module EveryDNS

  # Username and password were incorrect
  class LoginFailed < StandardError; end;
  # A requested EveryDNS::Domain did not exist when asked to perform an action
  class MissingDomainError < StandardError; end;
  # A requrested EveryDNS::Record was missing when asked to perform an action
  class MissingRecordError < StandardError; end;
  # Specific EveryDNS::Domain types can have DNS records associated with them
  class IncorrectDomainType < StandardError; end;
  
  EVERYDNS_HOSTNAME = 'www.everydns.com'
  HTTP_USER_AGENT = 'RbEveryDNS'
  SESSION_TIMEOUT = 10 *60
  
  # These messages are returned as query string variables in HTTP redirect
  # responses. They are used to confirm the successfull completion of a 
  # request
  RESPONSE_MESSAGES = {
    :LOGIN_FAILED           => 'Login failed, try again!',
    :DOMAIN_ADDED_PRIMARY   => '%s has been added to the database.',
    :DOMAIN_ADDED_DYNAMIC   => '%s has been added to the database as dynamic.',
    :DOMAIN_ADDED_SECONDARY => '%s has been added to the database as secondary with \'%s\' as nameserver.',
    :DOMAIN_ADDED_WEBHOP    => '%s has been added to the database as webhop.',
    :DOMAIN_DELETED         => 'Domain %s has been deleted.',
    :DOMAIN_EXISTS          => '%s already exists in database.',
    :DOMAIN_LIST_RECORDS    => 'Editing Domain %s.',
    :RECORD_ADDED           => 'Added Record successfully',
    :RECORD_DELETED         => "Record Delete Succeeded"
  }
  
  # The main interface for managing EveryDNS domains. Provide your
  # username and password to the client then perform desired rquests.
  # 
  # Inteligently caches authentication and other commands to help reduce
  # the amount of HTTP requests to perform
  class Client
    require 'base64'
    require 'net/http'
    require 'uri'
    
    attr_reader :username, :password, :request_count
    
    # Create an instance of the client using the provided username and password
    # to authenticate
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
    
    def inspect
      "<%s %s %s>" % [self.class, self.username, (self.authenticated? ? 'authenticated' : 'unathenticated')]
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
    
    # Login raising LoginFailed error if unsuccessful
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
      return @domain_list unless @domain_list.nil?
      login!
      res = get('/manage.php')
      @domain_list = DomainList.parse_list(res.body)
    end
    
    # Add a host as a domain managed by EveryDNS. Options:
    # 
    # Types:
    #   * :secondary
    #   * :dynamic
    #   * :webhop
    # 
    # When secondary <tt>option</tt> is the primary domain, and when webhop
    # is the address of the destination url. Otherwise not needed.
    def add_domain(host, type = :primary, option=nil)
      domain = Domain.new(host, nil, type, option)
      login!
      res = post '/dns.php', domain.create_options
      if response_status_message(res) == (RESPONSE_MESSAGES["DOMAIN_ADDED_#{type}".upcase.intern] % [host, option])
        clear_domain_cache!
        return true
      else
        return false
      end
    end
    
    # Removes the requested domain from the EveryDNS account:
    #   remove_domain('domain.com')   # deletes domain.com and DNS records
    #   list_domains                  # domain.com is now gone
    def remove_domain(host)
      domain = find_domain!(host)
      res = post '/dns.php', domain.delete_options
      if response_status_message(res) == (RESPONSE_MESSAGES[:DOMAIN_DELETED] % host)
        clear_domain_cache!
        return true
      else
        return false
      end
    end
    
    # Returns an EveryDNS::RecordList for the given host:
    # 
    #   records = list_records 'domain.com'   # > EveryDNS::RecordList
    #   records[:MX]                          # Array of all MX records
    #   records.each do |record|              # Iterates with EveryDNS::Record
    #   puts record.host
    #   puts record.value
    #   end
    # 
    def list_records(host)
      domain = find_domain!(host)
      raise IncorrectDomainType, "Domain #{host} is a #{domain.type} domain" unless domain.can_have_records?
      
      return @domain_records[domain.host] unless @domain_records.nil? or @domain_records[domain.host].nil?
      
      res = get('/dns.php', domain.list_records_options)
      if response_status_message(res) == (RESPONSE_MESSAGES[:DOMAIN_LIST_RECORDS] % domain.host)
        record_list = RecordList.parse_list(domain, get(URI.join("http://#{EVERYDNS_HOSTNAME}/dns.php", res['location']).to_s).body)
        cache_domain_records(domain.host, record_list)
        return record_list
      else
        return false
      end
    end
    
    # Adds a DNS record for specified domain
    # 
    # add_record 'domain.com', 'domain.com', :A, '192.168.0.1
    # add_record 'domain.com', 'www.domain.com', :CNAME, 'domain.com'
    # add_record 'domain.com', 'mail.domain.com', :MX, 10
    # 
    def add_record(domain, host, type, value, mx_priority='', ttl=7200)
      domain = find_domain!(domain)
      raise IncorrectDomainType, "Domain #{host} is a #{domain.type} domain" unless domain.can_have_records?
      record = Record.new(domain, host, type, value, mx_priority, ttl)
      response = post('/dns.php', record.create_options)
      if response_status_message(response) == RESPONSE_MESSAGES[:RECORD_ADDED]
        clear_domain_records_cache!(domain)
        true
      else
        false
      end
      
    end
    
    # Deletes a given record, must provide the domain as well as combination of
    # 
    # * The EveryDNS::Record <tt>id</tt>
    # * The host and type e.g.
    # 
    #   remove_record 'domain.com', 145698
    #   remove_record 'domain.com', 'mail.domain.com', :MX
    # 
    def remove_record(domain, *args)
      domain = find_domain!(domain)
      raise IncorrectDomainType, "Domain #{host} is a #{domain.type} domain" unless domain.can_have_records?
      record = args.first.is_a?(Record) ? record : list_records(domain)[*args]
      raise MissingRecordError, "Record does not exist" if record.nil? || record.new?
      
      response = get('/dns.php', record.delete_options)
      if response_status_message(response) == RESPONSE_MESSAGES[:RECORD_DELETED]
        clear_domain_records_cache!(domain)
        true
      else
        puts response_status_message(response)
        false
      end
      
    end
    
    # Parses the reponse message from the querystring of a Net::HTTPRedirection
    # response from everydns.com
    # 
    # The messages are stored in the query string variable <tt>msg</tt> and
    # are encoded using Base64
    def response_status_message(http_response)
      return false unless http_response.is_a?(Net::HTTPRedirection)
      query = URI.parse(http_response['location']).query
      return false if query.nil?
      return Base64.decode64(query.decode_query_string['msg'])
    end
    
    private

      def domains
        @domain_list ||= list_domains
      end
      
      def find_domain(host)
        domains[host]
      end
      
      def find_domain!(host)
        return host if host.is_a?(Domain)
        domain = find_domain(host)
        raise MissingDomainError, "Domain #{host} does not exist" unless domain.is_a?(Domain)
        domain
      end
      
      def clear_domain_cache!
        @domain_list = nil
      end
      
      def find_domain_record(domain, *id_or_host_and_type)
        domain_records(domain)[id_or_host_and_type]
      end
      
      def domain_records(host)
        host = domain.host if host.is_a?(Domain)
        return @domain_records[domain] if @domain_records && @domain_records.key?(domain)
        @domain_records = Hash.new if @domain_records.nil?
        records = list_records(host)
        @domain_records.merge!(host => records)
        records
      end
      
      def clear_domain_records_cache!(host)
        host = host.host if host.is_a?(Domain)
        return if @domain_records.nil?
        @domain_records.delete host
      end
      
      def cache_domain_records(host, record_list)
        @domain_records = Hash.new if @domain_records.nil?
        @domain_records[host] = record_list
      end
      
      def post path, data
        @request_count += 1
        update_cookies(http_client.post(path, data.to_query_string, prepare_headers))
      end
      
      def get path, data=nil
        @request_count += 1
        path << "?#{data.to_query_string}" unless data.nil?
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