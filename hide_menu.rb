add_header_proc do
  unless @user
    <<-HTML
    <style type="text/css"><!--
    div.adminmenu {
      display: none;
    }
    --></style>
    HTML
  end
end
