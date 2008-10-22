#
# tagz.rb doesn't cramp your style, allowing even invalid html to be
# generated.  note the use of the 'tagz' method, which can be used both to
# capture output and to append content to the top of the stack.
#

require 'tagz'
include Tagz.globally

def header
  tagz{
    html_
      body_(:class => 'ninja-like', :id => 'giraffe-slayer')

      tagz << "\n<!-- this is the header -->\n"
  }
end

def footer
  tagz{
    tagz << "\n<!-- this is the footer -->\n"

    body_
      html_
  }
end

puts header, footer
