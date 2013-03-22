
##
## hiki plugin to support several html tags
##


##
## <sub> tag
##
## usage:
##    X{{sub(i)}}         #=> X<sub>i</sub>
##    X{{sub(i, true)}}   #=> X<sub><em>i</em></sub>
##
def sub(text, em=false)
  if em
    "<sub><em>#{text}</em></sub>"
  else
    "<sub>#{text}</sub>"
  end
end

##
## <sup> tag
##
## usage:
##    X{{sup(2)}}         #=> X<sup>2</sup>
##    X{{sup(2, true)}}   #=> X<sup><em>2</em></sup>
##
def sup(text, em=false)
  if em
    "<sup><em>#{text}</em></sup>"
  else
    "<sup>#{text}</sup>"
  end
end

##
## <ruby> tag
##
## usage:
##    {{ruby(S, sekai-wo, O, ooini-moriagerutame-no, S, suzumiya-haruhi-no, Brigade)}}
##      #=> <ruby>S<rp>(</rp><rt>sekai-wo</rt><rp>)</rp>O<rp>(</rp><rt>ooini-moriagerutame-no</rt><rp>)</rp>S<rp>(</rp><rt>suzumiya-haruhi-no</rt><rp>)</rp>Brigade</ruby>
##
def ruby(*args)
  s = "<ruby>"
  while ! args.empty?
    text = args.shift
    yomi = args.shift
    s << text.to_s
    s << "<rp>(</rp><rt>#{yomi}</rt><rp>)</rp>" if yomi
  end
  s << "</ruby>"
  s
end

## register methods
export_plugin_methods(:sub, :sup, :ruby)
