require 'test_helper'

class RecordTest < TestCase
  
  def test_creat_options
    @record = EveryDNS::Record.new(@domain, 'sub.somewhere.com', :cname, 'google.com')
    assert_equal({
      'action'  => 'addRecord',
      'did'     => '1',
      'domain'  => 'somewhere.com',
      'field1'  => 'sub.somewhere.com',
      'type'    => '2',
      'field2'  => 'google.com',
      'mxVal'   => '',
      'ttl'     => '7200'
    }, @record.create_options)
  end
  
  def test_create_options_dynamic
    @domain = EveryDNS::Domain.new('somewhere.com', 1, :dynamic)
    @record = EveryDNS::Record.new(@domain, 'sub.somewhere.com', :cname, 'google.com')
    assert_equal({
      'action'  => 'addDynamicRecord',
      'dynid'     => '1',
      'domain'  => 'somewhere.com',
      'field1'  => 'sub.somewhere.com',
      'type'    => '2',
      'field2'  => 'google.com',
      'mxVal'   => '',
      'ttl'     => '7200'
    }, @record.create_options)
  end
  
  def test_delete_options
    @record = EveryDNS::Record.new(@domain, 'sub.somewhere.com', :cname, 'google.com', '', 7200, 5)
    assert_equal({'action' => 'deleteRec', "rid"=>'5', "domain"=>"c29tZXdoZXJlLmNvbQ==", "did"=>"1"}, @record.delete_options)
  end
  
  def test_delete_options_dynamice
    @domain = EveryDNS::Domain.new('somewhere.com', 1, :dynamic)
    @record = EveryDNS::Record.new(@domain, 'sub.somewhere.com', :cname, 'google.com', '', 7200, 5)
    assert_equal({'action' => 'deleteRec', "dynrid"=>'5', "domain"=>"c29tZXdoZXJlLmNvbQ==", "dynid"=>"1"}, @record.delete_options)
  end
  
  protected
  
    def setup
      @domain = EveryDNS::Domain.new('somewhere.com', 1)
    end
  
end