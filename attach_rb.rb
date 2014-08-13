# -*- coding: utf-8 -*-
def attach_rb(file_name, start_no=1, page=@page)
  return '' if /\A\.\./ =~ file_name
  Dir::mkdir("#{@cache_path}/attach_rb/") unless File::directory?("#{@cache_path}/attach_rb/")
  cachedir = "#{@cache_path}/attach_rb/#{escape(page.untaint)}"
  Dir::mkdir(cachedir) unless File::directory?(cachedir)
  file = "#{@cache_path}/attach/#{escape(page.untaint)}/#{escape(file_name.untaint)}"
  cache_file = "#{cachedir}/#{escape(file_name.untaint)}"
  if test(?r, cache_file) and File::mtime(cache_file) > File::mtime(file)
    return File.read(cache_file)
  else
  require "irb/ruby-lex"
  require "stringio"

  tabstop = ' ' * (@options['attach.tabstop'] ? @options['attach.tabstop'].to_i : 2)

  code = File.read(file).to_utf8.gsub(/^\t+/) {|t| tabstop * t.size}
  code.sub!(/\s*\z/, "\n")
  io = StringIO.new(code)
  chars = code.split(//)
  
  s = ""
  scanner = RubyLex.new
  scanner.exception_on_syntax_error = false
  scanner.set_input(io)
  
  s << %Q!<pre>!
  line = start_no !=- 1 ? start_no-1 : 0
  seek = 0
  prev = nil
  while token = scanner.token
    if prev
      text = chars[prev.seek...token.seek].join
      seek = token.seek
      if line!=prev.line_no + (start_no != -1 ? start_no - 1 : 0)
        line = prev.line_no + (start_no != -1 ? start_no - 1 : 0)
        s << "<span class=\"LineNumber\">%4d|</span>" % line if start_no != -1
      end
      case prev
      when RubyToken::TkNL
        s << "\n"
      else
        type = prev.class.to_s.sub("RubyToken::","")
        text = CGI::escapeHTML(text)
        if text.count("\n")==0
          s << "<span class=\"#{type}\">"+text+"</span>"
        else
          start = 0
          idx = text.index("\n")
          while idx
            s << "<span class=\"#{type}\">" << text[start...idx] << "</span>\n"
            line = line + 1
            s << "<span class=\"rb.LineNumber\">%4d|</span>" % line if start_no != -1
            start = idx + 1
            idx = text.index("\n",start)
          end
          if start<text.size
            s << "<span class=\"#{type}\">" << text[start..-1] << "</span>"
          end
        end
      end
      prev = token
    else
      prev = token
    end
  end
  s << %Q!</pre>!
  s.gsub!(%r|\r*\n*</span>|, '</span>')
  open(cache_file.untaint, "w") do |f|
    f.print s
  end
  s
  end
end
