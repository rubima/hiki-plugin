# speakerdeck.rb: Embed speakerdeck slide on hiki pages.
#
# Copyright (C) 2013- sunaot <sunao.tanabe@gmail.com>
# You can redistribute it and/or modify it under GPL2.
#
# This plugin depends on jquery-oembed.
#   - https://code.google.com/p/jquery-oembed/

add_header_proc {
  <<-IMPORT_SCRIPT
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
  <script type="text/javascript" src="/js/jquery.oembed.js"></script>
  IMPORT_SCRIPT
}

add_body_leave_proc {
  <<-SCRIPT
  <script type="text/javascript">
          $(document).ready(function() {
                  $("a.oembed").oembed(null, {
                          maxWidth: 640,
                          maxHeight: 480
                  });
          });
  </script>
  SCRIPT
}

def oembed title, url
  return <<-EMBED_SLIDE
  <div><a href="#{url}" class="oembed">#{title}</a></div>
  EMBED_SLIDE
end

alias speakerdeck oembed
alias slideshare oembed
