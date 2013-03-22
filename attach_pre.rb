## Usage: attach_pre('file.html', 'page=foo&linenum=1&inline=true')
def attach_pre(filename, option_str='page=nil&amp;linenum=nil&amp;inline=false')
  # parse option string
  #$stderr.puts "*** debug: option_str=#{option_str.inspect}"
  page    = @page
  linenum = nil
  inline  = false
  if option_str
    options = {}
    option_str.split(/\&amp;/).each do |option|
      if option =~ /\A(\w+)=(.*)/
        key = $1; val = $2
        case val
        when 'true', 'yes' ;  val = true
        when 'false', 'no' ;  val = false
        when 'nil', 'null' ;  val = nil
        when /\A\d+\z/     ;  val = val.to_i
        end
      else
        key = option; val = true
      end
      options[key] = val
    end
    #$stderr.puts "*** debug: options=#{options.inspect}"
    v = options['page'];     page    = v if v.is_a?(String)
    v = options['linenum'];  linenum = v if v.is_a?(Integer) || v == nil
    v = options['inline'];   inline  = v if v == true || v == false
  end

  #if filename =~ /\.(txt|rd|rb|c|pl|py|sh|java|html|htm|css|xml|xsl|sql|yaml|rhtml|xhtml|php|eruby)\z/i

    # read file content
    filepath = "#{@conf.cache_path}/attach/#{page.untaint.escape}/#{filename.untaint.escape}"
    content = File.open(filepath) { |f| f.read() }

    # add line number, expand tab character, and escape HTML character
    s = ''
    n = linenum.is_a?(Integer) ? linenum - 1 : 0
    content.each_line do |line|
      s << "%03d| " % (n += 1) if linenum     # add line number
      s << line.gsub(/([^\t]{8})|([^\t]*)\t/n) { [$+].pack("A8") }  # expand tab
    end
    s = s.escapeHTML.to_euc

    # inline expantion
    if inline
      # '{{*...*}}' => '<strong>...</strong>'
      s.gsub!(/\{\{\*/, '<strong>') 
      s.gsub!(/\*\}\}/, '</strong>')
      # '{{/.../}}' => '<em>...</em>'
      s.gsub!(/\{\{\//, '<em>')
      s.gsub!(/\/\}\}/, '</em>')
    end

    # return value
    "<pre>#{s}</pre>"

  #end
end



