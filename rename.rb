# rename.rb
#   version 1.1.0
#
# GNU General Public License Vrsion 2
#   Copyright (c) 2012 wantora <http://d.hatena.ne.jp/wantora/>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 'fileutils'

module Hiki
	class Rename < Command
		def rename
			unless @request.params['new_name']
				rename_form
			else
				rename_exec
			end
		end

		def rename_form
			rename_output(<<-EOS, "#{@p} - #{rename_label}")
<form class="update" action="./" method="post">
<p>
  #{new_name_label}
  <input type="text" name="new_name" maxlength="50" size="30" value="">
  <input type="hidden" name="p" value="#{escapeHTML(@p)}">
  <input type="hidden" name="c" value="rename">
  <input type="submit" value="#{escapeHTML(rename_label)}">
</p>
<p>
  <input type="checkbox" name="alias">#{alias_label}
</p>
</form>
			EOS
		end

		def rename_exec
			old_name = @p
			new_name = @request.params['new_name']

			return rename_failed unless rename_page(old_name, new_name)

			if @request.params['alias']
				return rename_failed unless rename_alias(old_name, new_name)
			end

			rename_output(<<-EOS, rename_label)
<dl>
<dt>#{old_name_label}</dt>
<dd>#{escapeHTML(old_name)}</dd>
<dt>#{new_name_label}</dt>
<dd>#{@plugin.hiki_anchor(escape(new_name), @plugin.page_name(new_name))}</dd>
</dl>
			EOS
		end

		private

		def rename_failed
			rename_output(failed_label, "#{@p} - #{rename_label}")
		end

		def rename_page(old_name, new_name)
			unless @db.exist?(new_name)
				content = @db.load(old_name)
        if File.exist?("#{@conf.cache_path}/attach/#{escape(old_name)}")
          FileUtils.mv("#{@conf.cache_path}/attach/#{escape(old_name)}", "#{@conf.cache_path}/attach/#{escape(new_name)}")
        end
				if rename_page_save(new_name, content, "")
					rename_page_delete(old_name)
					true
				end
			end
		end

		def rename_alias(old_name, new_name)
			content = @db.load("AliasWikiName") || ""
			md5hex = @db.md5hex("AliasWikiName")

			content = content.sub(/[^\n\r]\z/, "\\&\n") + "*[[#{new_name}:#{old_name}]]\n"

			rename_page_save("AliasWikiName", content, md5hex)
		end

		def rename_page_save(page, src, md5)
			rename_tmp_page(page) do
				@plugin.save(page, src, md5)
			end
		end

		def rename_page_delete(page)
			rename_tmp_page(page) do
				@db.delete(page)
				@plugin.delete_proc
			end
		end

		def rename_tmp_page(page)
			old_page = nil
			@plugin.instance_eval do
				old_page = @page
				@page = page
			end
			yield
		ensure
			@plugin.instance_eval{ @page = old_page } if old_page
		end

		def rename_output(s, title_str)
			# from hiki/contrib/plugin/rast-search.rb
			parser = @conf.parser::new(@conf)
			tokens = parser.parse('')
			formatter = @conf.formatter::new(tokens, @db, @plugin, @conf)
			@page = Page::new(@request, @conf)
			data = get_common_data(@db, @plugin, @conf)
			@plugin.hiki_menu(data, @cmd)
			data[:title] = title(title_str)
			data[:view_title] = title_str
			data[:body] = formatter.apply_tdiary_theme(s)
			@cmd = 'plugin' # important!!!
			generate_page(data) # private method inherited from Command class
		end
	end
end

def rename
	Hiki::Rename.new(@request, @db, @conf).rename
end

add_body_enter_proc(Proc.new do
	add_plugin_command('rename', rename_label, {'p' => true})
end)
