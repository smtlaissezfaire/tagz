#
# tagz.rb mixes quite easily with your favourite templating engine, avoiding
# the need for '<% rows.each do |row| %> ... <% row.each do |cell| %> '
# madness and other types of logic to be coded in the templating language,
# leaving templating to template engines and logic and looping to ruby -
# unencumbered by extra funky syntax
#

require 'tagz'
include Tagz.globally

require 'erb'

rows = %w( a b c ), %w( 1 2 3 )

template = ERB.new <<-ERB
  <html>
    <body>
      <%=

        if rows

          table_{
            rows.each do |row|
              tr_{
                row.each do |cell|
                  td_{ cell }
                end
              }
            end
          }

        end

      %>
    </body>
  </html>
ERB

puts template.result(binding)

