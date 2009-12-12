require 'test_helper'

USERNAME = 'rb_client'
PASSWORD = 'rb_client_test'

class EveryDNSTest < Test::Unit::TestCase
  
  def test_sanity_check
    assert EveryDNS.is_a?(Module)
    assert EveryDNS::Client.is_a?(Class)
  end
  
  def test_login_successfully
    client = default_client
    assert client.login
  end
  
  def test_unsuccessful_login
    client = EveryDNS::Client.new(USERNAME, 'wrongpass')
    assert !client.login
  end
  
  def test_list_domains
    client = default_client
    assert client.
            list_domains.collect {|domain| domain.host }.
              include?('somewhere.com')
  end
  
  def test_session_timeout
    client = default_client
    assert_equal client.login, client.login
    client.login
    assert_equal 2, client.request_count
  end
  
  protected
  
    def default_client
      EveryDNS::Client.new(USERNAME, PASSWORD)
    end
  
end