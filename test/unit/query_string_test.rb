require 'test_helper'

class QueryStringTest < Test::Unit::TestCase

  def test_string
    assert_equal 'test', 'test'.to_query_string
    assert_equal 'test=test', "test".to_query_string('test')
  end
  
  def test_array
    assert_equal '[]=test', ['test'].to_query_string()
  end
  
  def test_hash
    assert_equal 'other=test&test=test', {'test'=>'test','other'=>'test'}.to_query_string()
  end
  
  def test_mixed
    assert_equal 'name[last]=collins&name[first]=beau&cars[][volvo][color]=silver&cars[][volvo][type]=suv&cars[][ford][color]=red&cars[][ford][type]=suv', {
      'name' => {
        'first' => 'beau',
        'last' => 'collins'
      },
      'cars' => [
        'volvo' => {
          'color' => 'silver',
          'type' => 'suv'
        },
        'ford' => {
          'color' => 'red',
          'type' => 'suv'
        }
      ]
    }.to_query_string
  end
  
end