def attach_html(file_name, start_no=1, page=@page)
  tabstop = ' ' * (@options['attach.tabstop'] ? @options['attach.tabstop'].to_i : 2)

  file = "#{@cache_path}/attach/#{page.untaint.escape}/#{file_name.untaint.escape}"
  code = File::readlines(file).join.gsub(/^\t+/) {|t| tabstop * t.size}.to_utf8.sub(/\n\z/,'')
  s = ""
  s << %Q!<pre>!
  line = start_no !=- 1 ? start_no : 1
  s << "<span class=\"html_linenumber\">%4d|</span>" % line if start_no != -1
  code.scan(/(\{\{.+?\}\})|(<%.+?%>)|(<!.+?>)|(<.+?>)|(&[a-zA-Z\#0-9]+;?)|([^<{\n]+)|(\n)|./m) {|str|
    m = $~
    if m[1]     # Web::Template
      str = CGI::escapeHTML(m[0])
      str.each_line {|x|
        s << "<span class=\"html_webtemplate\">" << x << "</span>"
        if x=~/\n\z/
          line += 1
          s << "<span class=\"html_linenumber\">%4d|</span>" % line if start_no != -1
        end
      }
    elsif m[2]  # ERb
      str = CGI::escapeHTML(m[0])
      str.each_line {|x|
        s << "<span class=\"html_erb\">" << x << "</span>"
        if x=~/\n\z/
          line += 1
          s << "<span class=\"html_linenumber\">%4d|</span>" % line if start_no != -1
        end
      }
    elsif m[3]  # comment
      str = CGI::escapeHTML(m[0])
      str.each_line {|x|
        s << "<span class=\"html_comment\">" << x << "</span>"
        if x=~/\n\z/
          line += 1
          s << "<span class=\"html_linenumber\">%4d|</span>" % line if start_no != -1
        end
      }
    elsif m[4]  # tag
      str = CGI::escapeHTML(m[0])
      tag_m = str.match(/&lt;\/?([a-z0-9]+)/i)
      if tag_m[1]=~/^(?:html|head|body|p|h[1-6]|ul|ol|pre|dl|div|blockquote|form|hr|table)/i
        str.each_line {|x|
          s << "<span class=\"html_tag_block\">" << x << "</span>"
          if x=~/\n\z/
            line += 1
            s << "<span class=\"html_linenumber\">%4d|</span>" % line if start_no != -1
          end
        }
      else
        str.each_line {|x|
          s << "<span class=\"html_tag\">" << x << "</span>"
          if x=~/\n\z/
            line += 1
            s << "<span class=\"html_linenumber\">%4d|</span>" % line if start_no != -1
          end
        }
      end
    elsif m[5]  # charref
      s << "<span class=\"html_charref\">" << CGI::escapeHTML(m[0]) << "</span>"
    elsif m[6]  # text
      s << CGI::escapeHTML(m[0])
    elsif m[7]  # lf
      line += 1
      s << "\n<span class=\"html_linenumber\">%4d|</span>" % line if start_no != -1
    end
  }
  s << %Q!</pre>!
  s
end
