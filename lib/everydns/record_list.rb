require 'everydns/record'

module EveryDNS
  
  class RecordList
    
    def initialize
      @records = []
    end
    
    Record::VALID_TYPES.each do |type|
      define_method "#{type}".downcase do
        @records.select { |record| record.type == type}
      end
    end
    
    def parse_list(html)
      
      # start by scanning for the table
      anchor_index = html.index 'Current Records:'
      
      
      if anchor_index > 0
        
        start_index = html.index '<table', anchor_index
        end_index = html.index '</table>', start_index
        
        while true
          start_index = html.index '<tr', start_index
          break if start_index < 0 || start_index > end_index
          end_row = html.index '</tr>', start_index
          break if end_row < 0 || end_row > end_index
          row_string = html[Range.new(start_index, end_row)]
          @records << parse_record(row_string)
          start_index = end_row + '</tr>'.length
        end
        
        @records.compact!
        
      else
        return false
      end
      
    end
    
    def parse_record(row_html)
      matches = row_html.scan(/<td><div.*?><font.*?>(.*?)<\/font>/).collect { |match|
        match.to_s.strip
      }
      if matches.length == 5
        return Record.new(*matches.push(row_html.scan(/<a href="\.?\/dns\.php\?action=delete(Rec|DynamicRec)&(dynrid|rid)=([\d]+)[^"]+/).last))
      end
      matches
    end
      
  end
  
end