require 'test_helper'

class DomainListTest < TestCase
  
  DOMAINS = {
    :primary => ['somewhere.com','somewhere2.com'],
    :secondary => ['secondarydomain.com', 'secondarydomain2.com'],
    :dynamic => ['dynamicdomain.com'],
    :webhop => ['webhopdomain.com','webhopdomain2.com']
  }
      
  def test_parse_domains
    
    domain_list = EveryDNS::DomainList.parse_list(File.read('test/fixtures/manage.html'))
    assert_equal DOMAINS.inject([]){|memo, pair| memo + pair.last }.sort, domain_list.collect(&:host).sort
    DOMAINS.each do |key, value|
      assert_equal value, domain_list.send(key).collect(&:host)
    end
    
    domain_list.each do |domain|
      assert_not_nil domain.id, "Domain #{domain.host} has a nil id"
      assert (domain.id > 0), "Domain #{domain.host} has an empty id"
    end
    
    somewhere = domain_list['somewhere.com']
    assert_equal 'somewhere.com', somewhere.host
    assert_equal 1043529, somewhere.id
    
  end
  
end