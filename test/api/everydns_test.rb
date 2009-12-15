require 'test_helper'

USERNAME = 'rb_client'
PASSWORD = 'rb_client_test'

# This test actually runs agains the live server. Not ideal but trying to keep
# it limited
class EveryDNSTest < Test::Unit::TestCase
  
  def test_sanity_check
    assert EveryDNS.is_a?(Module)
    assert EveryDNS::Client.is_a?(Class)
  end
  
  def test_unsuccessful_login
    client = EveryDNS::Client.new(USERNAME, 'wrongpass')
    assert !client.login
  end
  
  def test_list_domains
    client = default_client
    assert client.
            list_domains.collect(&:host).
              include?('somewhere.com')
  end
  
  def test_session_timeout
    client = default_client
    assert_equal client.login, client.login
    client.login
    assert_equal 1, client.request_count
  end
  
  def test_add_and_remove_domain
    client = default_client
    # Add primary
    assert client.add_domain('newtestdomainrbclient.name')
    assert_not_nil client.list_domains['newtestdomainrbclient.name'].id
    assert client.remove_domain('newtestdomainrbclient.name')
    
    # Add dynamic
    assert client.add_domain('newtestdomainrbclient.name', :dynamic)
    assert client.list_domains['newtestdomainrbclient.name'].dynamic?
    assert client.remove_domain('newtestdomainrbclient.name')
    
    # Add secondary
    assert client.add_domain('newtestdomainrbclient.name', :secondary, 'primarydomain.com')
    assert client.list_domains['newtestdomainrbclient.name'].secondary?
    assert_equal client.list_domains['newtestdomainrbclient.name'].option, 'primarydomain.com'
    assert client.remove_domain('newtestdomainrbclient.name')
    
    # Add webhop
    assert client.add_domain('newtestdomainrbclient.name', :webhop, 'http://www.google.com')
    assert client.list_domains['newtestdomainrbclient.name'].webhop?
    assert_equal client.list_domains['newtestdomainrbclient.name'].option, 'http://www.google.com'
    assert client.remove_domain('newtestdomainrbclient.name')
    
  end
  
  def test_list_domains_records
    
    client = default_client
    record_list = client.list_records('somewhere.com')
    assert record_list.is_a?(EveryDNS::RecordList)
    assert_not_nil record_list.a_records
    assert_not_nil record_list.mx_records
    assert_equal 1, record_list.a_records.length
    assert_equal 1, record_list.cname_records.length
    
  end
  
  def test_add_and_remove_record
    client = default_client
    assert client.add_record('somewhere.com', 'test.somewhere.com', :CNAME, 'google.com')
    assert client.list_records('somewhere.com').collect(&:host).include?('test.somewhere.com')
    record = client.list_records('somewhere.com')['test.somewhere.com', :CNAME]
    assert !record.new?
    assert client.remove_record('somewhere.com', record.id)
    
  end
  
  protected
  
    def default_client
      EveryDNS::Client.new(USERNAME, PASSWORD)
    end
  
end