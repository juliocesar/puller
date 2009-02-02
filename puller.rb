require 'rubygems'
require 'sinatra'

SHARE_PATH = File.join(File.dirname(__FILE__), 'share')

def file_list(path)
  files = Dir["#{path}/**"]
end

get '/' do
  @my_files = file_list(SHARE_PATH)
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
%table
  %thead
    %tr
      %th{ :class => 'left' } File name
      %th{ :class => 'right'} Size
  %tfoot
  %tbody
    - @my_files.each do |file|
      %tr
        %td.left= file
        %td.right= File.size file