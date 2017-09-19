require 'net/http'
require 'open-uri'
require 'htmlentities'
require 'open-uri'
require 'socket'
require 'nokogiri'
require 'json'

def http_get(url, headers = nil)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https' 
    http.open_timeout = 3
    http.read_timeout = 3
    response = http.get(uri.request_uri, headers)
    return response.body
end

def premarket(symb)
    txt = http_get("http://m.nasdaq.com/symbol/#{symb}/premarket")
    last_sale = txt.split("\n").select{|l| l.include? "last-sale"}[0]
    last_sale = Nokogiri::XML.parse(last_sale.strip.sub('$','')).text.to_f
    last_sale = 1 if last_sale == 0

    change = txt.split("\n").select{|l| l.include? "net-change"}[0]
    
    if (change.include? "red") then
        change = - Nokogiri::XML.parse(change.strip.sub('$','')).text.to_f
    elsif (change.include? "green") then
        change = Nokogiri::XML.parse(change.strip.sub('$','')).text.to_f
    else
        STDERR.puts "unknown html #{change}"
        exit(-1)
    end if change != nil

    change = "0.0".to_f if change == nil

    return [symb, last_sale, (change*100/last_sale).round(2), change]        
end

symbs = ['amzn', 'adbe', 'tsla', 'nvda', 'fit', 'gpro', 'baba', 'amd', 'grmn', 'aapl']
# symbs = ['grmn']
changes = symbs.map{|s| premarket(s)}.sort_by{|s| -s[2]}
changes.each{|c|
    puts "#{c[0]}\t #{c[2]}%\t #{c[3]} #{c[1]}"
}
