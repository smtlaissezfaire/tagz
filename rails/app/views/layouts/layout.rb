%( <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> ) +

html_( 'xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"' ){
  head_{ title_{ @title } }

  body_{ |body|
    hr_!
    body << yield(:foo)

    hr_!
    body << yield

    hr_!
    body << "bar : #{ @bar }"
  }
}
