(function($) {
  $.puller = {
    hosts: [],
    showHost: function(host) {
      var table = $([
        '<div id="host-', host.name, '" style="display: none" class="host">',
          '<h1>', host.name, '</h1>',
          '<p>', host.comment, '</p>',
          '<table id="host-', host.name, '">',
            '<thead>',
              '<tr>',
                '<th class="name">File name</th>',
                '<th class="size">Size</th>',
              '</tr>',
            '</thead>',
            '<tbody />',
          '</table>',
        '</div>'
      ].join('')).appendTo('#wrap');
      $.puller.loadFilesFor(host);
      table.show('slow');      
    },
    loadFilesFor: function(host) {
      $('#host-' + host.name + ' tbody').empty();
      $(host.files).each(function(i, file) {
        $('#host-' + host.name + ' tbody').append([
          '<tr>',
            '<td class="name">',
              '<a href="http://' + [host.hostname, host.port].join(':') + '/files/' + file.name + '">',
                file.name,
              '</a>',
            '</td>',
            '<td class="size">' + file.size + '</td>',
          '</tr>'
        ].join(''));
      });
    },
    startPolling: function() {
      this.poller = setInterval($.puller.getHosts, 3000)
    },
    hostIsLoaded: function(host) {
      return ($('#host-' + host.name).length > 0)
    },
    getHosts: function() {
      $.getJSON('/hosts', function(hosts) {
        $(hosts).each(function(i, host) {
          if (!$.puller.hostIsLoaded(host)) {            
            $.puller.hosts.push(host);
            $.puller.showHost(host);
          } else {
            $.puller.loadFilesFor(host);
          }
        });
      })
      // clearTimeout($.puller.poller);
    }
  }
})(jQuery);

$(document).ready(function() {
  $.puller.getHosts();
  $.puller.startPolling();
});