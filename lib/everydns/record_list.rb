require 'everydns/record'

module EveryDNS
  
  class RecordList
    
    def self.parse_list(domain, html)
      list = self.new(domain)
      list.parse_list(html)
      return list
    end
    
    def initialize(domain)
      raise ArgumentError "domain is not an instance of EveryDNS::Domain" unless domain.is_a?(Domain)
      @domain = domain
      @records = []
    end
    
    Record::VALID_TYPES.each do |type|
      define_method "#{type}_records".downcase do
        self.select(&"#{type}_record?".downcase.intern)
      end
    end
    
    def [](*args)
      
      return detect { |record| record.id == args.first  } if args.first.is_a?(Integer)
      return select { |record| record.host =~ args.first } if args.first.is_a?(Regexp)
      
      type = args.first if args.length == 1 && args.first.is_a?(Symbol)
      type = args.last if (args.length == 2)
      host = args.first if args.length == 1 && args.first.is_a?(String) 
      host = args.first if (args.length == 2)
      
      if host && type
        detect {|record| record.host == host && record.type == type}
      else
        select {|record| record.host == host || record.type == type}
      end
      
    end
    
    include Enumerable
    def each
      @records.each { |record| 
        yield record
      }
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
        return Record.new(*matches.push(row_html.scan(/<a href="\.?\/dns\.php\?action=delete(Rec|DynamicRec)&(dynrid|rid)=([\d]+)[^"]+/).last.last).unshift(@domain))
      end
    end
      
  end
  
end