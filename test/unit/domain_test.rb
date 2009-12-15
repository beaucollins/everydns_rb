require 'test_helper'

class DomainTest < TestCase
  include EveryDNS
    
  def test_base64
    domain = Domain.new('google.com')
    assert_equal "Z29vZ2xlLmNvbQ==", domain.host_base64
  end
    
  def test_primary_domain
    domain = Domain.new('www.google.com')
    assert_equal domain.host, 'www.google.com'
    assert domain.new?
    assert domain.primary?
    assert_equal({
      'action'    => 'addDomain',
      'newdomain' => 'www.google.com'
    }, domain.create_options)
  end
  
  def test_primary_delete_options
    domain = Domain.new('www.google.com', 1, :primary)
    assert_equal({
      'action'  => 'confDomain',
      'deldid'     => '1'
    }, domain.delete_options)
  end
  
  def test_secondary_domain
    domain = Domain.new('secondary.com', nil, :secondary, 'primary.com')
    assert !domain.primary?
    assert domain.secondary?
    assert_equal({
      'action'    => 'addDomain',
      'newdomain' => 'secondary.com',
      'sec'       => 'sec',
      'ns'        => 'primary.com'
    }, domain.create_options)
  end
  
  def test_dynamic_domain
    domain = Domain.new('dynamic.com', nil, :dynamic)
    assert_equal({
      'action'    => 'addDomain',
      'newdomain' => 'dynamic.com',
      'sec'       => 'dyn'
    }, domain.create_options)
  end
  
  def test_dynamic_delete_options
    domain = Domain.new('www.google.com', 1, :dynamic)
    assert_equal({
      'action'  => 'confDomain',
      'dynid'   => '1'
    }, domain.delete_options)
  end

  def test_webhop_domain
    domain = Domain.new('webhop.com', nil, :webhop, 'http://www.geocities.com/name')
    assert_equal({
      'action'    => 'addDomain',
      'newdomain' => 'webhop.com',
      'sec'       => 'webhop',
      'hop'       => 'http://www.geocities.com/name'
    }, domain.create_options)
  end
  
end