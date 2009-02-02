require 'rubygems'
require 'sinatra'

SHARE_PATH = File.join(File.dirname(__FILE__), 'share')
MY_FILES = Dir["#{SHARE_PATH}/**"].map { |f| File.basename f }

# get '/files/:filename' do
#   "omg #{params[:filename]}"
#   # if @my_files.include? params[:filename]
#   #   send_data params[:filename]
#   # end
# end

get '/files/*' do
  send_file File.join(SHARE_PATH, params["splat"])
end

get '/' do
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
    - MY_FILES.each do |file|
      %tr
        %td.left
          %a{ :href => "/files/#{file}", :alt => "#{file}" }= file
        %td.right= File.size File.join(SHARE_PATH, file)