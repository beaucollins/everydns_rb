require 'test_helper'

class RecordListTest < TestCase
  
  def test_parse_list
    
    record_list = EveryDNS::RecordList.new
    record_list.parse_list(File.read('test/fixtures/record_list.html'))
    
  end
  
end