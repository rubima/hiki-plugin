def social_buttons
  <<-_E
  <div class="social-buttons" style="text-align:right">
      <!-- hatena bookmark button -->
      <a href="http://b.hatena.ne.jp/entry/#{@request.base_url.sub(/^https?:\/\//, '')}?#{@conf.options['page']}" class="hatena-bookmark-button" title="Add this entry to Hatena Bookmark"><img src="http://b.st-hatena.com/images/entry-button/button-only.gif" alt="Add this entry to Hatena Bookmark" width="20" height="20" style="border: none;" /></a>
      <script type="text/javascript" src="http://b.st-hatena.com/js/bookmark_button.js" charset="utf-8"></script>
      <!-- like button -->
      <iframe src="http://www.facebook.com/plugins/like.php?href=#{CGI.escape @request.base_url}?#{@conf.options['page']}&amp;layout=button_count&amp;show_faces=true&amp;width=100&amp;action=like&amp;font=arial&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:100px; height:21px;" allowTransparency="true"></iframe>
      <!-- tweet button -->
      <a href="http://twitter.com/share" class="twitter-share-button" data-count="horizontal" data-via="">Tweet</a>
      <script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
      <script type="text/javascript" src="https://d1xnn692s7u6t6.cloudfront.net/widget.js"></script>
      <script type="text/javascript">(function k(){window.$SendToKindle&&window.$SendToKindle.Widget?$SendToKindle.Widget.init({}):setTimeout(k,500);})();</script>
      <div class="kindleWidget" style="display:inline-block;padding:3px;cursor:pointer;font-size:11px;font-family:Arial;white-space:nowrap;line-height:1;border-radius:3px;border:#ccc thin solid;color:black;background:transparent url('https://d1xnn692s7u6t6.cloudfront.net/button-gradient.png') repeat-x;background-size:contain;"><img style="vertical-align:middle;margin:0;padding:0;border:none;" src="https://d1xnn692s7u6t6.cloudfront.net/white-15.png" /><span style="vertical-align:middle;margin-left:3px;">Send to Kindle</span></div>
    </div>
  _E
end

add_body_enter_proc do
  social_buttons
end
