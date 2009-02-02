require 'rubygems'
require 'sinatra'

helpers do
  
  def file_list(path)
    files = Dir["#{path}/**"]
  end
  
end


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
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/theme_default.css' }
  %body
    #wrap
      #header
        %span.puller
          puller
        %span.arrow
          <-
      = yield 

@@ home
%p 
  Oh hai
