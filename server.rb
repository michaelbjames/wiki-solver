# require 'sinatra'
# require 'sinatra-websocket'
# require 'nokogiri'
# require 'open-uri'
# require 'json'
require 'sequel'
require 'ruby-prof'

# set :server, 'thin'
# set :sockets, []

WIKIBASE = 'http://en.wikipedia.org/wiki/'

MYDATABASE = "mysql://root:notasecret@localhost/wiki"
DB = Sequel.connect(MYDATABASE)

# def valid_wiki(name)
#   begin
#     open(WIKIBASE + name)
#   rescue OpenURI::HTTPError => e
#     return false
#   end
#   return true
# end

def neighbors(name)
  link_numbers = DB[:page].filter(:page_title => name).map(:page_id)
  linked_names = link_numbers.map do |e| 
    DB[:pagelinks].filter(:pl_from => e).map(:pl_title)
    end
  return linked_names.flatten
end


# def neighbors(name)
#   article = Nokogiri::HTML(open(WIKIBASE + name))
#   connected = Array.new
#   article.css('#mw-content-text a').each do |link|
#       value = link.attr('href')
#       next if value =~ /.*:.*/
#       if value =~ /^\/wiki\/.*$/
#         connected << value.gsub("/wiki/","")
#       end
#   end
#   connected.uniq
# end

def find_path(start, finish)
  dist = Hash.new{|k,v| v = Float::INFINITY}
  visited = Hash.new{|k,v| v = false}
  previous = Hash.new
  queue = Array.new
  seq = Array.new
  current = ""

  dist[start] = 0
  queue << start

  while queue.length > 0
    current = queue.shift
    # puts "#{previous[current]} -> #{current}"
    if current.casecmp(finish) == 0
      while(!previous[current].nil?)
        seq << current
        current = previous[current]
      end
      seq << start
      puts seq.reverse.to_s
      return seq
    end

    visited[current] = true

    neighbors(current).each do |neighbor|
      alt = dist[current] + 1
      if(alt < dist[neighbor])
        dist[neighbor] = alt
        previous[neighbor] = current
        unless visited[neighbor]
          queue << neighbor
        end
      end
    end
  end
  return 'No Solution'
end

result = RubyProf.profile {
  find_path('Franz_Liszt','Symphonic_poem')
}
open("callgrind.profile", "w") do |f|
  RubyProf::CallTreePrinter.new(result).print(f, :min_percent => 1)
end

# get '/solve' do
#   if !request.websocket?
#     status 400
#     body 'Please use a websocket to connect'
#     return
#   end

#   request.websocket do |ws|

#     ws.onclose do
#       warn('websocket closed')
#       settings.sockets.delete(ws)
#     end

#     ws.onopen do
#       if params[:start].nil?
#         ws.send({:type => 'error', :message => 'Missing start parameter'}.to_json)
#         ws.close_connection_after_writing
#         return
#       end
#       if params[:end].nil?
#         ws.send({:type => 'error', :message => 'Missing end parameter'}.to_json)
#         ws.close_connection_after_writing
#         return
#       end

#       start = params[:start]
#       finish = params[:end]

#       unless valid_wiki(start)
#         ws.send({:type => 'error', :message => 'Start article does not exist'}.to_json)
#         ws.close_connection_after_writing
#         return
#       end
#       unless valid_wiki(finish)
#         ws.send({:type => 'error', :message => 'End article does not exist'}.to_json)
#         ws.close_connection_after_writing
#         return
#       end

#       settings.sockets << ws
#       dijkstra(start,finish,ws)
#     end
#   end

#   return
# end
