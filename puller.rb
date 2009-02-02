require 'rubygems'
require 'sinatra'

get '/' do
  haml :home
end

get '/screen.css' do
  content_type 'text/css', :charset => 'utf-8'
  erb :style
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
  %body
    = yield 

@@ home
%p 
  Oh hai
