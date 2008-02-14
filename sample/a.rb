require 'tagz'
#
# the simplest way to use tagz is to include the module and genrate something
# tagged
#

include Tagz

puts html_{ body_{ 'content' } }
