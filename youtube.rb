# -*- coding: utf-8 -*-
# youtube.rb
# 引数はYouTubeのURLに含まれるvパラメタの値
# 例: {{youtube 'ApSBG0TntTU'}}
# 例: {{youtube 'ApSBG0TntTU', 300, 300}}
# referenced from sho-h http://sho.tdiary.net/20060708.html#p03
def youtube(video_id, width=560, height=315)
   <<-TAG
   <object width="#{width}" height="#{height}"><param name="movie" value="http://www.youtube.com/v/#{video_id}"></param><embed src="http://www.youtube.com/v/#{video_id}" type="application/x-shockwave-flash" width="#{width}" height="#{height}"></embed></object>
  TAG
end
