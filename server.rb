require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'pry'

WIKIBASE = 'http://en.wikipedia.org/wiki/'

def neighbors(name)
  article = Nokogiri::HTML(open(WIKIBASE + name))
  # binding.pry
  connected = Array.new
  article.css('#mw-content-text a').each do |link|
      value = link.attr('href')
      if value =~ /^\/wiki\/.*$/
        connected.push(value.gsub('/wiki/',''))
      end
  end
  puts connected.uniq
  connected.uniq
end

def dijkstra(start, finish)
  
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
  neighbors(params[:start])
  'Hello world!'
end