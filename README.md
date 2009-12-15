A Ruby client for the [EveryDNS][everydns] domain service. Uses Net::HTTP and
HTML scraping to communicate with EveryDNS.

  [everydns]: http://everydns.com "EveryDNS website"
  
Currently supports the adding and removing of domains with A, CNAME, NS, MX,
TXT, AAAA records (only those who have donated to EveryDNS can add TXT records).

## Install

Sorry, not yet packaged up as a gem:

    git clone git://github.com/beaucollins/everydns_rb.git
    cd everydns_rb/lib
    irb -r everydns
    

## Example:

    require 'everydns'
    
    client = EveryDNS::Client.new('username', 'password')
    
    # returns an EveryDNS::DomainList object
    client.list_domains
    
    # Adds domain 'domain.com' to list of domains managed by EveryDNS
    client.add_domain 'domain.com'
    
    # Adds domain 'secondary.com' mirroring 'primary.com'
    client.add_domain 'secondary.com', :secondary, 'domain.com'
    
    # now lists added domain as managed by EveryDNS
    client.list_domains
    
    # List records for specified domain, returns EveryDNS::DomainList
    domain_list = client.list_records 'domain.com'
    
    # Array of only MX records
    domain_list.mx_records
    
    # Array of only CNAME records
    domain_list.cname_records
    
    # now add a record and show list with new record
    clinet.list_records 'domain.com'
    client.add_record 'domain.com', 'domain.com', :A, '192.168.0.1'
    

There are still some rough edges. One design goal was to have no dependencies
so no additional dependencies need to be installed. There is a good amount of
test coverage to keep this sane.

## TODO:

  * Additional error checking and input sanitization to ensure proper host names
    and IP addresses
  * CLI utility
  * Bootable web interface via Sinatra/Rack?
    
## Credits

Started as a port from [Scott Yang][scottyang]'s python [EveryDNS utility][python].

  [scottyang]: http://scott.yang.id.au/ "Scott Yang's website"
  [python]: http://hostingfu.com/article/everydns-python-api-and-command-shell "EveryDNS Python Utility"