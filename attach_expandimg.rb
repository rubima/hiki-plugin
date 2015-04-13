def attach_expandimg(file1,file2=nil,page=@page)
    if(file2.nil?)
        attach_image_anchor(file1,page)
    else
        s =  %Q!<a href="!
        s << %Q!#{@conf.cgi_name}#{cmdstr('plugin', "plugin=attach_download;p=#{escape(page)};file_name=#{escape(file2)}")}">!
        s << %Q!#{attach_image_anchor(file1,page)}</a>!
    end
end
