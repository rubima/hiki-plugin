# attach_color_keywords.rb - Hiki plugin to highlight a keyword with a color
#
# Installation:
#   Copy or symlink this file into misc/plugin, and activate this
#   plugin and attach plugin from configuration interface
#
# Usage:
#   Upload a text file using attach plugin and write the
#   following code in the page:
#     {{attach_color_keywords(FILENAME, 'KEYWORD', COLOR)}}
#
#   FILENAME: name of the uploaded file
#   KEYWORD: keyword(s) to be highlighted
#   COLOR: color name of color code
#
# Copyright (C) 2007 zunda <zunda at freeshell.org>
#
# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#

def attach_color_keywords(file_name, keyword, color, page = @page)
	return '' unless file_name =~ /\.(txt|rd|rb|c|pl|py|sh|java|html|htm|css|xml|xsl|sql|yaml)\z/i
	page_file_name = "#{page.untaint.escape}/#{file_name.untaint.escape}"
	path = "#{@conf.cache_path}/attach/#{page_file_name}"
	unless File.exists?(path)
		raise PluginError, "No such file:#{page_file_name}"
	end
	src = File.open(path){|f| f.read}
	pre_color_keywords(src, {keyword => color}, @options)
end

def pre_color_keywords(string, colors = {}, options = {})
  tabstop = ' ' * (options['attach.tabstop'] ? options['attach.tabstop'].to_i : 2)

	unless colors.keys.empty?
		span_string = ''
		remaining = string.gsub(/(.*?)(\b#{Regexp.union(*colors.keys)}\b)/m) do
			prefix = $1
			key = $2
			span_string += prefix.escapeHTML
			span_string += %Q|<span style="color:#{colors[key].escapeHTML}">#{key.escapeHTML}</span>|
			''
		end
		span_string += remaining.escapeHTML
	else
		span_string = string.escapeHTML
	end
	
	'<pre>' + span_string.gsub(/^\t+/){|t| tabstop * t.size}.to_utf8 + '</pre>'
end

if __FILE__ == $0
	require 'test/unit'
	require 'cgi'
	require 'nkf'

	class String
		def escapeHTML
			CGI::escapeHTML(self)
		end

		def to_utf8
			NKF::nkf('-m0 -w', self)
		end
	end

	class TestPreColorKeywords < Test::Unit::TestCase
		def test_simple
			assert_equal('<pre>test</pre>', pre_color_keywords('test'))
		end

		def test_escape
			assert_equal('<pre>&lt;test&gt;</pre>', pre_color_keywords('<test>'))
		end

		def test_red_pill
			assert_equal('<pre><span style="color:red">red</span> pill</pre>',
				pre_color_keywords('red pill', {'red' => 'red'}))
		end

		def test_take_the_red_pill
			assert_equal('<pre>Take the <span style="color:red">red</span> pill</pre>',
				pre_color_keywords('Take the red pill', {'red' => 'red'}))
		end

		def test_pill_makes_ill
			assert_equal('<pre>pill makes <span style="color:purple">ill</span>.</pre>', pre_color_keywords('pill makes ill.', {'ill' => 'purple'}))
		end

		def test_color_escape
			assert_equal('<pre><span style="color:&quot;bad&quot;">bad</span></pre>', pre_color_keywords('bad', {'bad' => '"bad"'}))
		end
	end
end
