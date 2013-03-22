def clear_float(position=nil)
  case position
  when /^\s*l/i
    "<br style='clear:left;'>"
  when /^\s*r/i
    "<br style='clear:right;'>"
  else
    "<br style='clear:both;'>"
  end
end
export_plugin_methods(:clear_float)
