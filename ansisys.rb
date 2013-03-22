#
# = ansisys.rb
# ANSI terminal emulator
# based on http://en.wikipedia.org/wiki/ANSI_escape_code
#
# Copyright:: Copyright (C) 2007 zunda <zunda at freeshell.org>
# License:: GPL - GPL3 or later
#
require 'webrick'

module AnsiSys
	module VERSION	#:nodoc:
		MAJOR = 0
		MINOR = 8
		TINY = 3

		STRING = [MAJOR, MINOR, TINY].join('.')
	end

	module CSSFormatter
		# make a CSS style-let from a Hash of CSS settings
		def hash_to_styles(hash, separator = '; ')
			unless hash.empty?
				return hash.map{|e| "#{e[0]}: #{e[1].join(' ')}"}.join(separator)
			else
				return nil
			end
		end
		module_function :hash_to_styles
	end

	module Guess
		# returns a $KCODE string according to guessed encoding
		def self.kcode(data)
			case NKF.guess(data)
			when NKF::EUC
				kcode = 'e'
			when NKF::SJIS
				kcode = 's'
			when NKF::UTF8
				kcode = 'u'
			else
				kcode = 'n'
			end
			return kcode
		end
	end

	class AnsiSysError < StandardError; end

	class Lexer
		# Control Sequence Introducer and following code
		PARAMETER_AND_LETTER = /\A([\d;]*)([[:alpha:]])/o
		CODE_EQUIVALENT = {
			"\r" => ['B'],
			"\n" => ['E'],
		}

		attr_reader :buffer

		# _csis_ is an Array of Code Sequence Introducers
		# which can be \e[, \x9B, or both
		def initialize(csis = ["\x1b["])	# CSI can also be "\x9B"
			@code_start_re = Regexp.union(*(CODE_EQUIVALENT.keys + csis))
			@buffer = ''
		end

		# add the String (clear text with some or no escape sequences) to buffer
		def push(string)
			@buffer += string
		end

		# returns array of tokens while deleting the tokenized part from buffer
		def lex!
			r = Array.new
			@buffer.gsub!(/(?:\r\n|\n\r)/, "\n")
			while @code_start_re =~ @buffer
				r << [:string, $`] unless $`.empty?
				if CODE_EQUIVALENT.has_key?($&)
					CODE_EQUIVALENT[$&].each do |c|
						r << [:code, c]
					end
					@buffer = $'
				else
					csi = $&
					residual = $'
					if PARAMETER_AND_LETTER =~ residual
						r << [:code, $&]
						@buffer = $'
					else
						@buffer = csi + residual
						return r
					end
				end
			end
			r << [:string, @buffer] unless @buffer.empty?
			@buffer = ''
			return r
		end
	end

	class Characters
		# widths of characters
		WIDTHS = {
			"\t" => 8,
		}

		attr_reader :string	# clear text
		attr_reader :sgr	# Select Graphic Rendition associated with the text

		def initialize(string, sgr)
			@string = string
			@sgr = sgr
		end

		# echo the string onto the _screen_ with initial cursor as _cursor_
		# _cursor_ position will be changed as the string is echoed
		def echo_on(screen, cursor, kcode = nil)
			each_char(kcode) do |c|
				w = width(c)
				cursor.fit!(w)
				screen.write(c, w, cursor.cur_col, cursor.cur_row, @sgr.dup)
				cursor.advance!(w)
			end
			return self
		end

		private
		# iterator on each character
		def each_char(kcode, &block)
			@string.scan(Regexp.new('.', nil, kcode)).each do |c|
				yield(c)
			end
		end

		# width of a character
		def width(char)
			if WIDTHS.has_key?(char)
				return WIDTHS[char]
			end
			case char.size	# expecting number of bytes
			when 1
				return 1
			else
				return 2
			end
		end
	end

	class Cursor
		# Escape sequence codes processed in this Class
		CODE_LETTERS = %w(A B C D E F G H f)

		attr_reader :cur_col	# current column number (1-)
		attr_reader :cur_row	# current row number (1-)
		attr_accessor :max_col	# maximum column number
		attr_accessor :max_row	# maximum row number

		def initialize(cur_col = 1, cur_row = 1, max_col = 80, max_row = 25)
			@cur_col = cur_col
			@cur_row = cur_row
			@max_col = max_col
			@max_row = max_row
		end

		# applies self an escape sequence code that ends with _letter_ as String
		# and with some _pars_ as Integers
		def apply_code!(letter, *pars)
			case letter
			when 'A'
				@cur_row -= pars[0] ? pars[0] : 1
				@cur_row = @max_row if @max_row and @cur_row > @max_row
			when 'B'
				@cur_row += pars[0] ? pars[0] : 1
				@cur_row = @max_row if @max_row and @cur_row > @max_row
			when 'C'
				@cur_col += pars[0] ? pars[0] : 1
			when 'D'
				@cur_col -= pars[0] ? pars[0] : 1
			when 'E'
				@cur_row += pars[0] ? pars[0] : 1
				@cur_col = 1
				@max_row = @cur_row if @max_row and @cur_row > @max_row
			when 'F'
				@cur_row -= pars[0] ? pars[0] : 1
				@cur_col = 1
				@max_row = @cur_row if @max_row and @cur_row > @max_row
			when 'G'
				@cur_col = pars[0] ? pars[0] : 1
			when 'H'
				@cur_row = pars[0] ? pars[0] : 1
				@cur_col = pars[1] ? pars[1] : 1
				@max_row = @cur_row if @max_row and @cur_row > @max_row
			when 'f'
				@cur_row = pars[0] ? pars[0] : 1
				@cur_col = pars[1] ? pars[1] : 1
				@max_row = @cur_row if @max_row and @cur_row > @max_row
			end
			if @cur_row < 1
				@cur_row = 1
			end
			if @cur_col < 1
				@cur_col = 1
			elsif @cur_col > @max_col
				@cur_col = @max_col
			end
			return self
		end

		# changes current location for a character with _width_ to be echoed
		def advance!(width = 1)
			r = nil
			@cur_col += width
			if @cur_col > @max_col
				line_feed!
				r = "\n"
			end
			return r
		end

		# check if a character with _width_ fits within the maximum columns,
		# feed a line if not
		def fit!(width = 1)
			r = nil
			if @cur_col + width > @max_col + 1
				line_feed!
				r = "\n"
			end
			return r
		end

		# feed a line
		def line_feed!
			@cur_col = 1
			@cur_row += 1
			@max_row = @cur_row if @max_row and @cur_row > @max_row
		end
	end

	# Select Graphic Rendition
	class SGR
		extend CSSFormatter

		# Escape sequence codes processed in this Class
		CODE_LETTERS = %w(m)

		# :normal, :bold, or :faint
		attr_reader :intensity

		# :off or :on
		attr_reader :italic

		# :none, :single, or :double
		attr_reader :underline

		# :off, :slow, or :rapid
		attr_reader :blink

		# :positive or :negative
		attr_reader :image

		# :off or :on
		attr_reader :conceal

		# :black, :red, :green, :yellow, :blue, :magenta, :cyan, or :white
		attr_reader :foreground

		# :black, :red, :green, :yellow, :blue, :magenta, :cyan, or :white
		attr_reader :background

		def initialize
			reset!
		end

		# true if all the attributes are same
		def ==(other)
			instance_variables.each do |ivar|
				return false unless instance_eval(ivar) == other.instance_eval(ivar)
			end
			return true
		end

		# resets attributes
		def reset!
			apply_code!('m', 0)
		end

		# applies self an escape sequence code that ends with _letter_ as String
		# and with some _pars_ as Integers
		def apply_code!(letter = 'm', *pars)
			raise AnsiSysError, "Invalid code for SGR: #{letter.inspect}" unless 'm' == letter
			pars = [0] unless pars
			pars.each do |code|
				case code
				when 0
					@intensity = :normal
					@italic = :off
					@underline = :none
					@blink = :off
					@image = :positive
					@conceal = :off
					@foreground = :white
					@background = :black
				when 1..28
					apply_code_table!(code)
				when 30..37
					@foreground = COLOR[code - 30]
					@intensity = :normal
				when 39
					reset!
				when 40..47
					@background = COLOR[code - 40]
					@intensity = :normal
				when 49
					reset!
				when 90..97
					@foreground = COLOR[code - 90]
					@intensity = :bold
				when 99
					reset!
				when 100..107
					@background = COLOR[code - 100]
					@intensity = :bold
				when 109
					reset!
				else
					raise AnsiSysError, "Invalid SGR code #{code.inspect}" unless CODE.has_key?(code)
				end
			end
			return self
		end

		# renders self as :html or :text _format_ - makes a <span> html scriptlet.
		# _colors_ can be Screen.default_css_colors(_inverted_, _bright_).
		def render(format = :html, position = :prefix, colors = Screen.default_css_colors)
			case format
			when :html
				case position
				when :prefix
					style_code = css_style(colors)
					if style_code
						return %Q|<span style="#{style_code}">|
					else
						return ''
					end
				when :postfix
					style_code = css_style(colors)
					if style_code
						return '</span>'
					else
						return ''
					end
				end
			when :text
				return ''
			end
		end

		# CSS stylelet
		def css_style(colors = Screen.default_css_colors)
			return CSSFormatter.hash_to_styles(css_styles(colors))
		end

		# a Hash of CSS stylelet
		def css_styles(colors = Screen.default_css_colors)
			r = Hash.new{|h, k| h[k] = Array.new}
			# intensity is not (yet) implemented
			r['font-style'] << 'italic' if @italic == :on
			r['text-decoration'] << 'underline' unless @underline == :none
			r['text-decoration'] << 'blink' unless @blink == :off
			case @image
			when :positive
				fg = @foreground
				bg = @background
			when :negative
				fg = @background
				bg = @foreground
			end
			fg = bg if @conceal == :on
			r['color'] << colors[@intensity][fg] unless fg == :white
			r['background-color'] << colors[@intensity][bg] unless bg == :black
			return r
		end

		private
		def apply_code_table!(code)
			raise AnsiSysError, "Invalid SGR code #{code.inspect}" unless CODE.has_key?(code)
			ivar, value = CODE[code]
			instance_variable_set("@#{ivar}", value)
			return self
		end

		CODE = {
			1 => [:intensity, :bold],
			2 => [:intensity, :faint],
			3 => [:italic, :on],
			4 => [:underline, :single],
			5 => [:blink, :slow],
			6 => [:blink, :rapid],
			7 => [:image, :negative],
			8 => [:conceal, :on],
			21 => [:underline, :double],
			22 => [:intensity, :normal],
			24 => [:underline, :none],
			25 => [:blink, :off],
			27 => [:image, :positive],
			28 => [:conceal, :off],
		}	# :nodoc:

		COLOR = {
			0 => :black,
			1 => :red,
			2 => :green,
			3 => :yellow,
			4 => :blue,
			5 => :magenta,
			6 => :cyan,
			7 => :white,
		}	# :nodoc:

	end

	class Screen
		# Escape sequence codes processed in this Class
		CODE_LETTERS = %w()	# :nodoc:

		def self.default_foreground; :white; end
		def self.default_background; :black; end

		# a Hash of color names for each intensity
		def self.default_css_colors(inverted = false, bright = false)
			r = {
				:normal => {
					:black => 'black',
					:red => 'maroon',
					:green => 'green',
					:yellow => 'olive',
					:blue => 'navy',
					:magenta => 'purple',
					:cyan => 'teal',
					:white => 'silver',
				},
				:bold => {
					:black => 'gray',
					:red => 'red',
					:green => 'lime',
					:yellow => 'yellow',
					:blue => 'blue',
					:magenta => 'fuchsia',
					:cyan => 'cyan',
					:white => 'white'
				},
				:faint => {
					:black => 'black',
					:red => 'maroon',
					:green => 'green',
					:yellow => 'olive',
					:blue => 'navy',
					:magenta => 'purple',
					:cyan => 'teal',
					:white => 'silver',
				},
			}

			if bright
				r[:bold][:black] = 'black'
				[:normal, :faint].each do |i|
					r[i] = r[:bold]
				end
			end

			if inverted
				r.each_key do |i|
					r[i][:black], r[i][:white] = r[i][:white], r[i][:black]
				end
			end

			return r
		end

		# a Hash of CSS stylelet to be used in <head>
		def self.css_styles(colors = Screen.default_css_colors, max_col = nil, max_row = nil)
			h = {
				'color' => [colors[:normal][:white]],
				'background-color' => [colors[:normal][:black]],
				'padding' => ['0.5em'],
			}
			h['width'] = ["#{Float(max_col)/2}em"] if max_col
			#h['height'] = ["#{max_row}em"] if max_row	# could not find appropriate unit
			return h
		end

		# CSS stylelet to be used in <head>.
		# Takes the same arguments as Screen::css_styles().
		def self.css_style(*args)
			return "pre.screen {\n\t" + CSSFormatter.hash_to_styles(self.css_styles(*args), ";\n\t") + ";\n}\n"
		end

		# a Hash of keys as rows,
		# which each value a Hash of keys columns and each value as
		# an Array of character, its width, and associated SGR
		attr_reader :lines

		# a Screen
		def initialize(colors = Screen.default_css_colors, max_col = nil, max_row = nil)
			@colors = colors
			@max_col = max_col
			@max_row = max_row
			@lines = Hash.new{|hash, key| hash[key] = Hash.new}
		end

		# CSS stylelet to be used in <head>
		def css_style
			self.class.css_style(@colors, @max_col, @max_row)
		end

		# register the _char_ at a specific location on Screen
		def write(char, char_width, col, row, sgr)
			@lines[Integer(row)][Integer(col)] = [char, char_width, sgr.dup]
		end

		# render the characters into :html or :text
		# Class name in CSS can be specified as _css_class_.
		# Additional stylelet can be specified as _css_style_.
		def render(format = :html, css_class = 'screen', css_style = nil)
			result = case format
			when :text
				''
			when :html
				%Q|<pre#{css_class ? %Q[ class="#{css_class}"] : ''}#{css_style ? %Q| style="#{css_style}"| : ''}>\n|
			else
				raise AnsiSysError, "Invalid format option to render: #{format.inspect}"
			end

			unless @lines.keys.empty?
				prev_sgr = nil
				max_row = @lines.keys.max
				(1..max_row).each do |row|
					if @lines.has_key?(row) and not @lines[row].keys.empty?
						col = 1
						while col <= @lines[row].keys.max
							if @lines[row].has_key?(col) and @lines[row][col]
								char, width, sgr = @lines[row][col]
								if prev_sgr != sgr
									result += prev_sgr.render(format, :postfix, @colors) if prev_sgr
									result += sgr.render(format, :prefix, @colors)
									prev_sgr = sgr
								end
								case format
								when :text
									result += char
								when :html
									result += WEBrick::HTMLUtils.escape(char)
								end
								col += width
							else
								result += ' '
								col += 1
							end
						end
					end
					result += "\n" if row < max_row
				end
				result += prev_sgr.render(format, :postfix, @colors) if prev_sgr
			end

			result += case format
			when :text
				''
			when :html
				'</pre>'
			end
			return result
		end

		# applies self an escape sequence code that ends with _letter_ as String
		# and with some _pars_ as Integers
		def apply_code!(letter, *pars)
			return self
		end	# :nodoc:
	end

	class Terminal
		# Escape sequence codes processed in this Class
		CODE_LETTERS = %w(J K S T n s u)

		# _csis_ is an Array of Code Sequence Introducers
		# which can be \e[, \x9B, or both
		def initialize(csis = ["\x1b["])
			@lexer = Lexer.new(csis)
			@stream = Array.new
		end

		# echoes _data_, a String of characters or escape sequences
		# to the Terminal.
		# This method actually just buffers the echoed data.
		def echo(data)
			@lexer.push(data)
			return self
		end

		# CSS stylelet to be used in <head>
		def css_style(format = :html, max_col = 80, max_row = nil, colors = Screen.default_css_colors)
			case format
			when :html
				Screen.css_style(colors, max_col, max_row)
			when :text
				''
			end
		end

		# renders the echoed data as _format_ of :html or :text.
		# _max_col_, _max_row_ can be specified as Integer.
		# _colors_ can be Screen.default_css_colors(_inverted_, _bright_).
		def render(format = :html, max_col = 80, max_row = nil, colors = Screen.default_css_colors, css_class = nil, css_style = nil, kcode = nil)
			css_class ||= 'screen'
			kcode ||= Guess.kcode(@lexer.buffer)
			screens = populate(format, max_col, max_row, colors, kcode)
			separator = case format
			when :html
				"\n"
			when :text
				"\n---\n"
			end
			return screens.map{|screen| screen.render(format, css_class, css_style)}.join(separator)
		end

		# applies self an escape sequence code that ends with _letter_ as String
		# and with some _pars_ as Integers
		def apply_code!(letter, *pars)
			case letter
			when 'J'
				cur_col = @cursor.cur_col
				cur_row = @cursor.cur_row
				lines = @screens[-1].lines
				if pars.empty? or 0 == pars[0]
					rs = lines.keys.select{|r| r > cur_row}
					cs = lines[cur_row].keys.select{|c| c >= cur_col}
				elsif 1 == pars[0]
					rs = lines.keys.select{|r| r < cur_row}
					cs = lines[cur_row].keys.select{|c| c <= cur_col}
				elsif 2 == pars[0]
					rs = lines.keys
					cs = []
					@cursor.apply_code!('H', 1, 1)
				end
				rs.each do |r|
					lines.delete(r)
				end
				cs.each do |c|
					lines[cur_row].delete(c)
				end
			when 'K'
				cur_col = @cursor.cur_col
				cur_row = @cursor.cur_row
				line = @screens[-1].lines[cur_row]
				if pars.empty? or 0 == pars[0]
					cs = line.keys.select{|c| c >= cur_col}
				elsif 1 == pars[0]
					cs = line.keys.select{|c| c <= cur_col}
				elsif 2 == pars[0]
					cs = line.keys
				end
				cs.each do |c|
					line.delete(c)
				end
			when 'S'
				lines = @screens[-1].lines
				n = pars.empty? ? 1 : pars[0]
				n.times do |l|
					lines.delete(l)
				end
				rs = lines.keys.sort
				rs.each do |r|
					lines[r-n] = lines[r]
					lines.delete(r)
				end
				@cursor.apply_code!('H', rs[-1] - n + 1, 1)
			when 'T'
				lines = @screens[-1].lines
				n = pars.empty? ? 1 : pars[0]
				rs = lines.keys.sort_by{|a| -a}	# sort.reverse
				rs.each do |r|
					lines[r+n] = lines[r]
					lines.delete(r)
				end
				@cursor.apply_code!('H', rs[-1] - n + 1, 1)
			when 's'
				@stored_cursor = @cursor.dup
			when 'u'
				@cursor = @stored_cursor.dup if @stored_cursor
			end

			return self
		end

		private
		def populate(format = :html, max_col = 80, max_row = nil, colors = Screen.default_css_colors, kcode = nil)
			@cursor = Cursor.new(1, 1, max_col, max_row)
			@stored_cursor = nil
			@screens = [Screen.new(colors, max_col, max_row)]
			@sgr = SGR.new
			@stream += @lexer.lex!
			@stream.each do |type, payload|
				case type
				when :string
					Characters.new(payload, @sgr).echo_on(@screens[-1], @cursor, kcode)
				when :code
					unless Lexer::PARAMETER_AND_LETTER =~ payload
						raise AnsiSysError, "Invalid code: #{payload.inspect}"
					end
					letter = $2
					pars = $1.split(/;/).map{|i| i.to_i}
					applied = false
					[@sgr, @cursor, @screens[-1], self].each do |recv|
						if recv.class.const_get(:CODE_LETTERS).include?(letter)
							recv.apply_code!(letter, *pars)
							applied = true
						end
					end
					raise AnsiSysError, "Invalid code or not implemented: #{payload.inspect}" unless applied
				end
			end
			return @screens
		end
	end
end

if defined?(Hiki) and Hiki::Plugin == self.class
	# a Hiki plugin method to render a file of text with ANSI escape sequences.
	# Attached file name should be specified as _file_name_.
	# _max_row_ can be specified.
	# _invert_ and _bright_ can be specified to change colors.
	# _page_ can be specified to show a file attached to another page.
	def ansi_screen(file_name, max_col = 80, invert = false, bright = true, page = @page)
		return '' unless file_name =~ /\.(txt|rd|rb|c|pl|py|sh|java|html|htm|css|xml|xsl|sql|yaml)\z/i 
		page_file_name = "#{page.untaint.escape}/#{file_name.untaint.escape}"
		path = "#{@conf.cache_path}/attach/#{page_file_name}"
		unless File.exists?(path)
			raise PluginError, "No such file:#{page_file_name}"
		end
		data = File.open(path){|f| f.read}.to_euc

		colors = AnsiSys::Screen.default_css_colors(invert, bright)
		styles = AnsiSys::CSSFormatter.hash_to_styles(AnsiSys::Screen.css_styles(colors, max_col, nil), '; ')

		terminal = AnsiSys::Terminal.new
		terminal.echo(data)
		return terminal.render(:html, max_col, nil, colors, 'screen', styles, 'e') + "\n"
	end
end
