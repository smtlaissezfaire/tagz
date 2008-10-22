#
# tagz.rb can generate really compact html.  this is great to save bandwidth
# but can sometimes make reading the generated html a bit rough.  of course
# using tidy or the dom inspector in firebug obviates the issue; nevertheless
# it's sometime nice to break things up a little.  you can use 'tagz << "\n"'
# or the special shorthand '__' to accomplish this
#

require 'tagz'
include Tagz.globally

p div_{
  span_{ true }
  __
  span_{ false }  # hey ryan, i fixed this ;-)
  __
}
