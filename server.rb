require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'pry'

WIKIBASE = 'http://en.wikipedia.org'

def neighbors(name)
  article = Nokogiri::HTML(open(WIKIBASE + name))
  # binding.pry
  connected = Array.new
  article.css('#mw-content-text a').each do |link|
      value = link.attr('href')
      next if value =~ /.*:.*/
      if value =~ /^\/wiki\/.*$/
        connected.push(value)
      end
  end
  connected.uniq
end

def dijkstra(start, finish)
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
    puts "inspecting #{u}"
    if u.casecmp(finish) == 0
      while(!previous[u].nil?)
        seq.push u
        u = previous[u]
      end
      seq.push start
      return seq
    end

    visited[u] = true

    neighbors(u).each do |hood|
      alt = dist[u] + 1
      if(alt < dist[hood])
        dist[hood] = alt
        previous[hood] = u
        unless visited[hood]
          q.push(hood)
        end
      end
    end
  end

end

get '/solve' do
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
  seq = dijkstra(start,finish)
  return seq.revers.to_s
end