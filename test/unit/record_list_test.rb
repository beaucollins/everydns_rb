require 'test_helper'

class RecordListTest < TestCase
  
  def test_parse_list
    
    record_list = EveryDNS::RecordList.new(@domain)
    record_list.parse_list(File.read('test/fixtures/record_list.html'))
    
    assert_equal 1, record_list.a_records.length
    assert_equal 1, record_list.cname_records.length
    assert_equal 0, record_list.mx_records.length
    
    assert record_list.a_records.collect(&:host).include?('someawesomedomain.name')
    assert record_list.cname_records.collect(&:host).include?('www.someawesomedomain.name')
    
  end
  
  def test_search_list
    record_list = EveryDNS::RecordList.parse_list(@domain, File.read('test/fixtures/record_list.html'))
    
    assert record_list.mx_records
    assert_equal Array, record_list['www.someawesomedomain.name'].class
    assert_equal 1, record_list['www.someawesomedomain.name'].length
    
    assert_equal EveryDNS::Record, record_list['www.someawesomedomain.name', :CNAME].class
    assert_equal 5759182, record_list['www.someawesomedomain.name', :CNAME].id
    
    assert_equal EveryDNS::Record, record_list[5759182].class
    
  end
  
  def setup
    @domain = EveryDNS::Domain.new('google.com', nil, :primary)
  end
  
end