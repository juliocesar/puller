$(document).ready(function() {
  $.getJSON('/hosts', function(hosts) {
    
    $(hosts).each(function(i, host) {
      var table = $([
        '<table id="host-' + host.name + '" style="display: none">',
          '<thead>',
            '<tr>',
              '<th class="name">File name</th>',
              '<th class="size">Size</th>',
            '</tr>',
          '</thead>',
          '<tfoot />',
          '<tbody />',
        '</table>'
      ].join('')).appendTo('#wrap');
      window.files = host.files;
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
      table.show();
      
    });
    
  });
});