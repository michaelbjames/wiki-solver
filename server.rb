require 'sinatra'
require 'sinatra-websocket'
require 'nokogiri'
require 'open-uri'
require 'json'

set :server, 'thin'
set :sockets, []

WIKIBASE = 'http://en.wikipedia.org/wiki/'

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
        connected << value.gsub("/wiki/","")
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
  q << start

  while q.length > 0
    u = q.shift
    return unless settings.sockets.include?(ws)
    ws.send({:type => 'progress', :previous => previous[u], :current => u}.to_json)
    puts "#{previous[u]} -> #{u}"
    if u.casecmp(finish) == 0
      while(!previous[u].nil?)
        seq << u
        u = previous[u]
      end
      seq << start
      puts seq.reverse.to_s
      ws.send({:type => 'solution', :solution => seq.reverse}.to_json)
      sleep 5
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
  ws.send({:type => 'error', :message => 'Unable to find a path between the two articles'}.to_json)
  ws.close_connection_after_writing
  return 'No Solution'
end

get '/solve' do
  if !request.websocket?
    status 400
    body 'Please use a websocket to connect'
    return
  end

  request.websocket do |ws|

    ws.onclose do
      warn('websocket closed')
      settings.sockets.delete(ws)
    end

    ws.onopen do
      if params[:start].nil?
        ws.send({:type => 'error', :message => 'Missing start parameter'}.to_json)
        ws.close_connection_after_writing
        return
      end
      if params[:end].nil?
        ws.send({:type => 'error', :message => 'Missing end parameter'}.to_json)
        ws.close_connection_after_writing
        return
      end

      start = params[:start]
      finish = params[:end]

      unless valid_wiki(start)
        ws.send({:type => 'error', :message => 'Start article does not exist'}.to_json)
        ws.close_connection_after_writing
        return
      end
      unless valid_wiki(finish)
        ws.send({:type => 'error', :message => 'End article does not exist'}.to_json)
        ws.close_connection_after_writing
        return
      end

      settings.sockets << ws
      dijkstra(start,finish,ws)
    end
  end

  return
end