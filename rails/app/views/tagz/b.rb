html_{
  head_{ title_{ @title } }

  body_{
    ul_{
      @list.each{|elem| li_{ elem } }
    }

    hr_!

    em_{ 'this gets added automatically to the em tag' }

    hr_!

    self << 'more content into the body'

    hr_!
  }
}
