def hiki_manu(data, command)
  menu = create_menu(data, command)
  if @user
    if @conf.mobile_agent?
      data[:tools] = menu.join('|')
    else
      data[:tools] = menu.collect! {|i| %Q!<span class="adminmenu">#{i}</span>! }.join("&nbsp;\n")
    end
  else
    data[:tools] = %Q!<span class="adminmenu"><a href="#{@conf.cgi_name}?c=login#{@page ? ";p=#{escape(@page)}" : ""}">#{@conf.msg_login}</a></span>!
  end
end
