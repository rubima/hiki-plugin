## parse from '<<<' to '>>>'
##
## ex. preformatted text
##   <<<
##   x: foo
##   y: bar
##   >>>
##
## result:
##   <pre>
##   x: foo
##   y: bar
##   </pre>
##
## ex. preformatted text with line numbers, inline marking, and class attribute
##   <<<: linenum=5, inline=true, class=console, format='%03d| '
##   x: {{*foo*}}
##   y: {{/bar/}}
##   >>>
##
## result:
##   <div style="text-align:right">
##    <a onclick="javascript:toggle_linenums(this)">hide line numbers</a>
##   </div>
##   <pre class="console">
##   <span>005|</span> x: <strong>foo</strong>
##   <span>006|</span> y: <em>bar</em>
##   </pre>
##
## If 'linenum' option is specified, '<a>hide line numbers</a>' is placed
## which can hide/show line numbers.
##
## Several short notations are provided.
## * '<<<#' is equivarent to '<<<: linenum=1'
## * '<<<*' is equivarent to '<<<: inline=true'
## * '<<<%' is equivarent to '<<<: class=console'
## * '<<<#*%' is equivarent to '<<<: linenum=1, inline=true, class=console'
##   (order of '#', '*', and '%' is not important)
## * '<<<#*: class=name' is also available
##
## Default format is '%03d: '.
##

require 'hikidoc'

class ::HikiDoc

  def parse_pre( text )
    ret = text
    ret.gsub!( /^#{MULTI_PRE_OPEN_RE}([#*%]*)(?::[ \t]+(.*?))?$(.*?)^#{MULTI_PRE_CLOSE_RE}$/m ) do |str|
      opts    = _parse_options($2)
      content = restore_pre($3)
      content = _manipulate_pre_content(content, opts, $1)
      prefix  = _toggle_linenums_anchor(opts, $1)
      stag, etag = _create_pre_tags(opts, $1)
      "\n" + prefix + store_block( "#{stag}#{content}#{etag}" ) + "\n\n"
    end
    ret.gsub!( /(?:#{PRE_RE}.*\n?)+/ ) do |str|
      str.chomp!
      str.gsub!( PRE_RE, '' )
      "\n" + store_block( "<pre>\n#{restore_pre(str)}\n</pre>" ) + "\n\n"
    end
    ret
  end

  def _toggle_linenums_script()
    return <<END
<script language="javascript" type="text/javascript">
<!--
;function toggle_linenum(elem_anchor) {
;  var label = elem_anchor.firstChild.nodeValue;
;  var action = label.substring(0, 4) == 'show' ? 'hide' : 'show';
;  elem_anchor.firstChild.nodeValue = action + ' line numbers';
;  var display = action == 'show' ? 'none' : 'inline';
;  var elem_pre = elem_anchor.parentNode.nextSibling;
;  for (var i = 0, n = elem_pre.childNodes.length; i < n; i++) {
;    var child = elem_pre.childNodes[i];
;    if (child.tagName == 'SPAN') {
;      child.style.display = display;
;    }
;  }
;}
-->
</script>
END
  end

  def _toggle_linenums_anchor(opts, optstr)
    flag_linenum = opts.fetch('linenum', optstr.include?('#') ? 1 : nil).is_a?(Integer)
    return '' unless flag_linenum
    anchor = '<div style="text-align:right;margin-bottom:-2em;font-size:small;"><a onclick="javascript:toggle_linenum(this);return false">hide line numbers</a></div>'
    return anchor if @_toggle_linenums
    @_toggle_linenums = true
    script = _toggle_linenums_script()
    return script + anchor
  end

  def _create_pre_tags(opts, optstr)
    class_attr = opts.fetch('class', optstr.include?('%') ? 'console' : nil)
    attr = class_attr ? " class=\"#{escape_quote(class_attr)}\"" : ""
    return "<pre#{attr}>", "</pre>"
  end

  # LINENUMS_DEFAULT_FORMAT = '%3d: '

  def _manipulate_pre_content(content, opts, optstr)
    optstr ||= ''
    linenum = opts.fetch('linenum', optstr.include?('#') ? 1 : nil)
    inline  = opts.fetch('inline',  optstr.include?('*'))
    # add line numbers
    if linenum.is_a?(Integer)
      n = linenum - 1
      # format = opts.fetch('format', LINENUMS_DEFAULT_FORMAT)
      format = opts.fetch('format', '%3d: ')
      content.gsub!(/\A\r?\n/, '')
      content.gsub!(/^/) { "<span>#{format % (n += 1)}</span>" }
      content = "\n" + content
    end
    # {{*text*}} => <strong>text</strong>, {{/text/}} => <em>text</em>
    if inline == true
      content.gsub!(/\{\{\*(.*?)\*\}\}/, '<strong>\1</strong>')
      content.gsub!(/\{\{\/(.*?)\/\}\}/, '<em>\1</em>')
      content.gsub!(/\{\{\}\}/, '')
    end
    return content
  end

  def _parse_options(option_str)
    opts = {}
    option_str.split(/\s*,\s*/).each do |option|
      if option =~ /\A(\w+)(?:=(.*))?/
        key, val = $1, $2
        case val
        when nil                 ;  val = true
        when 'true', 'yes'       ;  val = true
        when 'false', 'no'       ;  val = false
        when 'nil', 'null'       ;  val = nil
        when /\A[-+]?\d+\z/      ;  val = val.to_i
        when /\A[-+]?\d+\.\d+\z/ ;  val = val.to_f
        when /\A'(.*)'\z/        ;  val = $1
        when /\A"(.*)"\z/        ;  val = $1
        end
      else
        key, val = option, true
      end
      opts[key.strip] = val
    end if option_str
    return opts
  end

end
