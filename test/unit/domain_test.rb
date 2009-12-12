require 'test_helper'

class DomainTest < TestCase
  include EveryDNS
  
  DOMAINS = [
    'somewhere.com',
    'somewhere2.com',
    'secondarydomain.com',
    'secondarydomain2.com',
    'dynamicdomain.com',
    'webhopdomain.com',
    'webhopdomain2.com'
    ]
  
  def test_primary_domain
    domain = Domain.new('www.google.com')
    assert_equal domain.host, 'www.google.com'
    assert domain.new?
    assert domain.primary?
    assert_equal({ 'newdomain' => 'www.google.com' }, domain.create_options)
  end
  
  def test_secondary_domain
    domain = Domain.new('secondary.com', nil, :secondary, 'primary.com')
    assert !domain.primary?
    assert domain.secondary?
    assert_equal({
      'newdomain' => 'secondary.com',
      'sec' => 'sec',
      'ns' => 'primary.com'
    }, domain.create_options)
  end
  
  def test_dynamic_domain
    domain = Domain.new('dynamic.com', nil, :dynamic)
    assert_equal({
      'newdomain' => 'dynamic.com',
      'sec' => 'dyn'
    }, domain.create_options)
  end
  
  def test_webhop_domain
    domain = Domain.new('webhop.com', nil, :webhop, 'http://www.geocities.com/name')
    assert_equal({
      'newdomain' => 'webhop.com',
      'sec' => 'webhop',
      'hop' => 'http://www.geocities.com/name'
    }, domain.create_options)
  end
  
  def test_parse_domains
    domains = Domain.parse_list(File.read('test/fixtures/manage.txt'))
    assert_equal DOMAINS, domains.collect(&:host)
  end
  
end