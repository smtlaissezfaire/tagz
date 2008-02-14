class TagzController < ApplicationController
  include Tagz
  helper{ include Tagz }

  ### menu
  def index
    menu = %w( a b c d e ).map{|action| "<br><a href='#{ action }'>#{ action }</a>"}
    render :text => "<html> <body> #{ menu } </body> </html>"
  end

  ### setup a little data
  def initialize
    @title = 'tagz!'
    @list = %w( a b c )
  end

  ### just using tagz inline
  def a 
    text = tagz {
      html_{
        head_{ title_{ @title } }

        body_{
          ul_{ @list.each{|elem| li_{ elem } } }
        }
      }
    }

    render :text => text
  end

  ### using a simple template : app/views/tagz/b.rb
  def b
    render
  end

  ### using content_for : app/views/layouts/layout.rb app/views/tagz/c.rb
  def c
    render :layout => 'layout' 
  end

  ### mixing erb and tagz
  def d
    render
  end

  ### rendering fubar content see app/views/tagz/e.rb
  def e
    render
  end
end
