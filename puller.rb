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
    # def self.new(host, port, comment, files, format)
    def self.new(options = {}, format = :json)
      struct = { 
        :hostname => options[:hostname], 
        :port     => options[:port],
        :name     => options[:name],
        :comment  => options[:comment],
        :files    => options[:files].map { |f| { :name => f, :size => "%0.2f" % File.size(SHARED_PATH/f).to_megabytes + "M" } }
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
      Dir["#{SHARED_PATH}/**"].map { |f| File.basename f }
    end
  end
  
  class Config
    class Invalid < StandardError; end
    def initialize
      config = YAML.load_file SINATRA_ROOT/'config.yml'
      verify! config
      config.keys.each do |key|
        self.class.send(:attr_accessor, key)
        self.send("#{key}=", config[key])
      end
    end
    
    private
    def verify!(config)
      # a small set of rules to keep the config sane
      raise Invalid, "#{config['downloads_dir']} not a directory or is not readable" unless valid_dir?(config['downloads_dir'])
      raise Invalid, "#{config['shared_dir']} is not a directory or is not readable" unless valid_dir?(config['shared_dir'])
      raise Invalid, "#{config['name']} is not valid. Use only letters of numbers" unless valid_name?(config['name'])
    end
    
    def valid_dir?(dir)
      dir and File.directory?(SINATRA_ROOT/dir) and File.readable?(SINATRA_ROOT/dir)
    end
    
    def valid_name?(name)
      name and !!name[/^[a-zA-Z0-9]+$/]
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
        'name' => CONFIG.name,
        'comment' => CONFIG.comment
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

CONFIG = Puller::Config.new

SHARED_PATH     = SINATRA_ROOT/CONFIG.shared_dir
DOWNLOADS_PATH  = SINATRA_ROOT/CONFIG.downloads_dir

before do
  @puller = Puller::Core.new
end

get '/files/*' do
  send_file SHARED_PATH/params["splat"]
  # ^ don't... just don't
end

get '/files' do
  content_type :json
  Puller::Response.new(
    :hostname => Socket.gethostname, 
    :port     => 4567, 
    :name     => CONFIG.name,
    :comment  => CONFIG.comment, 
    :files    => @puller.my_files
  )
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
%html{ 'xml:lang' => 'en', :lang => 'en', :xmlns => 'http://www.w3.org/1999/xhtml' }
  %head
    %title "puller &lt;-"
    %meta{ 'http-equiv' => 'Content-type', :content => 'text/html; charset=utf-8' }
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/screen.css' }
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/theme_default.css' }
    %script{ :type => 'text/javascript', :src => '/jquery-1.3.1.min.js' }
    %script{ :type => 'text/javascript', :src => '/app.js' }
  %body
    #wrap
      = yield 

@@ home
%h3 My files
%table{ :id => 'my_files' }
  %thead
    %tr
      %th.name File name
      %th.size Size
  %tbody
    - @files.each do |file|
      %tr
        %td.name
          %a{ :href => "/files/#{file}" }= file
        %td.size= "%0.2f" % File.size(SHARED_PATH/file).to_megabytes + "M"
