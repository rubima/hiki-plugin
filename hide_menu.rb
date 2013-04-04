add_header_proc do
  unless @user
    <<-HTML
    <style type="text/css"><!--
    span.adminmenu {
      display: none;
    }
    --></style>
    HTML
  end
end
