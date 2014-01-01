require 'sinatra'
require 'sinatra-websocket'
require 'nokogiri'
require 'open-uri'
require 'json'

set :server, 'thin'
set :sockets, []

WIKIBASE = 'http://en.wikipedia.org'

def valid_wiki(name)
  begin
    open(WIKIBASE + name)
  rescue OpenURI::HTTPError => e
    return false
  end
  return true
end

def neighbors(name)
  article = Nokogiri::HTML(open(WIKIBASE + name))
  connected = Array.new
  article.css('#mw-content-text a').each do |link|
      value = link.attr('href')
      next if value =~ /.*:.*/
      if value =~ /^\/wiki\/.*$/
        connected << value
      end
  end
  connected.uniq
end

def dijkstra(start, finish, ws)
      dist = Hash.new{|k,v| v = Float::INFINITY}
   visited = Hash.new{|k,v| v = false}
  previous = Hash.new
         q = Array.new
       seq = Array.new
         u = ""

  dist[start] = 0
  q.push(start)

  while q.length > 0
    u = q.shift
    return unless settings.sockets.include?(ws)
    ws.send({:previous => previous[u], :current => u}.to_json)
    puts "inspecting #{u}"
    if u.casecmp(finish) == 0
      while(!previous[u].nil?)
        seq << u
        u = previous[u]
      end
      seq << start
      puts seq.reverse.to_s
      ws.send({:solution => seq.reverse}.to_json)
      ws.close_connection_after_writing
      return seq
    end

    visited[u] = true

    neighbors(u).each do |hood|
      alt = dist[u] + 1
      if(alt < dist[hood])
        dist[hood] = alt
        previous[hood] = u
        unless visited[hood]
          q << hood
        end
      end
    end
  end
  return 'No Solution'
end

get '/solve' do
  if !request.websocket?
    status 400
    body 'Please use a websocket to connect'
    return
  end
  if params[:start].nil?
    status 400
    body 'Missing start parameter'
    return
  end
  if params[:end].nil?
    status 400
    body 'Missing end parameter'
    return
  end
  start = '/wiki/' + params[:start]
  finish = '/wiki/' + params[:end]
  unless valid_wiki(start)
    status 400
    body 'The start address is not a valid en.wikipedia address'
    return
  end
  unless valid_wiki(finish)
    status 400
    body 'The end address is not a valid en.wikipedia address'
    return
  end

  request.websocket do |ws|
    ws.onopen do
      settings.sockets << ws
      dijkstra(start,finish,ws)
    end
    ws.onclose do
      warn('websocket closed')
      settings.sockets.delete(ws)
    end
  end

  return
end