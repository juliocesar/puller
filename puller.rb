# This is not necessary is it?
SINATRA_ROOT = File.dirname(__FILE__)
$:.concat Dir["#{SINATRA_ROOT}/vendor/*/lib"]

require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'
require 'net/dns/mdns-sd'
require 'net/dns/resolv-mdns'
require 'net/dns/resolv-replace'
require 'terminator'

# Mixins
class Fixnum
  def to_kilobytes
    self.to_f / 1024
  end
  
  def to_megabytes
    self.to_kilobytes / 1024
  end
end

class String
  def /(str)
    File.join(self, str)
  end
end

module Puller
  
  class HTTP
    
    def initialize
      @upload_queue = {}
    end
    
    def download
      # HTTP downloads happen by clicking on file links directly
      return true
    end
    
    # We'll accept POSTing to other people too! How cool is that.
    def upload(file, someone)
    end
  end
  
  class Response
    def self.new(host, port, comment, files, format)
      struct = { 
        :host     => Socket.gethostname, 
        :port     => port,
        :comment  => comment,
        :files    => files 
      }
      struct.send("to_#{format}")
    end
  end
  
  class BitTorrent
    # To do...
  end
  
  class Core
    def initialize
      @peer_discovery = PeerDiscovery.new
    end
    
    def peers
      @peer_discovery.peers
    end
    
    def my_files
      Dir["#{SHARE_PATH}/**"].map { |f| File.basename f }
    end
  end
  
  class PeerDiscovery
    DNSSD = Net::DNS::MDNSSD    
    
    def initialize(timesout_in = 5)
      @timesout_in = timesout_in
      @handle = DNSSD.register(
        'puller', 
        '_http._tcp', 
        'local', 4567, 
        'files' => '/files', 
        'comment' => 'omg awesome'
      )
    end
    
    def peers    
      _peers = discover
      peers_found = []
      _peers.each do |peer|
        http = Net::HTTP.new peer.target, peer.port
        path = peer.text_record['files']
        response = http.get peer.text_record['files'] || '/files'
        peers_found << JSON.parse(response.body)
      end
      peers_found
    end
    
    private
    def discover
      hosts = []
      Terminator.terminate(@timesout_in) do
        DNSSD.browse('_http._tcp') do |b|
          next unless b.name == 'puller' 
          DNSSD.resolve(b.name, b.type) do |reply|
            # next if reply.target == Socket.gethostname # exclude myself from peers list
            hosts << reply
          end
        end
      end
      return hosts      
    end
    
  end
    
end

SHARE_PATH      = SINATRA_ROOT/'share'
DOWNLOADS_PATH  = SINATRA_ROOT/'downloads'

before do
  @puller = Puller::Core.new
end

get '/files/*' do
  send_file SHARE_PATH/params["splat"]
  # ^ don't... just don't
end

get '/files' do
  content_type :json
  Puller::Response.new(Socket.gethostname, 4567, 'omg awesome', @puller.my_files, :json)
end

post '/files' do
  # files sent from others
end

get '/hosts' do
  content_type :json
  @puller.peers.to_json
end

get '/' do
  @files = @puller.my_files
  haml :home
end

__END__

@@ layout
!!! XML
!!! STRICT
%html
  %head
    %title "puller <-"
    %meta{ 'http-equiv' => 'Content-type', :content => 'text/html; charset=utf-8' }
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/screen.css' }
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/theme_default.css' }
    %script{ :type => 'text/javascript', :src => '/jquery-1.3.1.min.js' }
    %script{ :type => 'text/javascript', :src => '/app.js' }
  %body
    #header
      %span.puller puller
      %span.arrow <-
    #wrap
      = yield 

@@ home
%h3 My files
%table{ :id => 'my_files' }
  %thead
    %tr
      %th.name File name
      %th.size Size
  %tfoot  
  %tbody
    - @files.each do |file|
      %tr
        %td.name
          %a{ :href => "/files/#{file}", :alt => "#{file}" }= file
        %td.size= "%0.2f" % File.size(SHARE_PATH/file).to_megabytes + "M"
