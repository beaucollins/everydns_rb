require 'test_helper'
require 'everydns'

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
    assert_equal ['somewhere.com'], client.list_domains
  end
  
  protected
  
    def default_client
      EveryDNS::Client.new(USERNAME, PASSWORD)
    end
  
end