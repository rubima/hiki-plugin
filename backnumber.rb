def indices(re)
  re = Regexp.compile(re.gsub(/(?!\\)\#/, '\#'))
  str = "<ul>\n"
  @db.pages.sort.each do |page|
    if re =~ page
      if page == @page
        str << "<li><strong>#{h(page_name(page))}</strong>\n"
      else
        str << "<li>#{hiki_anchor(escape(page), page_name(page))}\n"
      end
    end
  end
  str << "</ul>\n"
end

def backnumber(title)
  indices("\\A[0-9]{4}-#{title}\\z")
end

export_plugin_methods(:backnumber, :indices)
