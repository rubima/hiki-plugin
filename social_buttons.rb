def social_buttons
  url_with_slash = @request.base_url.sub(/\/\Z/, '') + '/'
  <<-_E
  <div class="social-buttons" style="text-align:right">
      <!-- hatena bookmark button -->
      <a href="http://b.hatena.ne.jp/entry/#{url_with_slash.sub(/^https?:\/\//, '')}?#{@conf.options['page']}" class="hatena-bookmark-button" title="Add this entry to Hatena Bookmark"><img src="http://b.st-hatena.com/images/entry-button/button-only.gif" alt="Add this entry to Hatena Bookmark" width="20" height="20" style="border: none;" /></a>
      <script type="text/javascript" src="http://b.st-hatena.com/js/bookmark_button.js" charset="utf-8"></script>
      <!-- like button -->
      <iframe src="http://www.facebook.com/plugins/like.php?href=#{CGI.escape url_with_slash}?#{@conf.options['page']}&amp;layout=button_count&amp;show_faces=true&amp;width=100&amp;action=like&amp;font=arial&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:100px; height:21px;" allowTransparency="true"></iframe>
      <!-- tweet button -->
      <a href="http://twitter.com/share" class="twitter-share-button" data-count="horizontal" data-via="">Tweet</a>
      <script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>

    </div>
  _E
end

add_body_enter_proc do
  social_buttons
end
