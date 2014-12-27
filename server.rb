# require 'sinatra'
# require 'sinatra-websocket'
# require 'nokogiri'
# require 'open-uri'
# require 'json'
require 'sequel'
# require 'ruby-prof'

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

def neighbors(id)
  DB[:links].filter(:from_id => id).map(:to_id)
end

def id_to_name(id)
  DB[:page].filter(:page_id => id).first[:page_title]
end

def name_to_id(name)
  DB[:page].filter(:page_title => name).first[:page_id]
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

def find_path(start_name, finish_name)
  dist = Hash.new{|k,v| v = Float::INFINITY}
  visited = Hash.new{|k,v| v = false}
  previous = Hash.new
  queue = Array.new
  seq = Array.new
  current = ""

  start = name_to_id(start_name)
  finish = name_to_id(finish_name)

  dist[start] = 0
  queue << start

  while queue.length > 0
    current = queue.shift
    # puts "#{previous[current]} -> #{current}"
    if current == finish
      while(!previous[current].nil?)
        seq << current
        current = previous[current]
      end
      seq << start
      seq.map! {|e| id_to_name(e)}
      puts seq.to_s
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
