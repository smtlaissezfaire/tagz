require 'test/unit'
STDOUT.sync = true
$:.unshift 'lib'
$:.unshift '../lib'
$:.unshift '.'
require 'tagz'

class TagzTest < Test::Unit::TestCase
  include Tagz

  class ::String
    Equal = instance_method '=='
    remove_method '=='
    def == other
      Equal.bind(self.delete(' ')).call other.to_s.delete(' ')
    end
  end

  def test_000
    expected = '<foo  ></foo>'
    actual = tagz{ 
      foo_
      _foo
    }
    assert_equal expected, actual
  end

  def test_010
    expected = '<foo  ><bar  ></bar></foo>'
    actual = tagz{ 
      foo_
        bar_
        _bar
      _foo
    }
    assert_equal expected, actual
  end

  def test_020
    expected = '<foo  ><bar  /></foo>'
    actual = tagz{ 
      foo_
        bar_{}
      _foo
    }
    assert_equal expected, actual
  end

  def test_030
    expected = '<foo  ><bar /></foo>'
    actual = tagz{ 
      foo_{
        bar_{}
      }
    }
    assert_equal expected, actual
  end

  def test_040
    expected = '<foo  >bar</foo>'
    actual = tagz{ 
      foo_{ 'bar' }
    }
    assert_equal expected, actual
  end

  def test_050
    expected = '<foo  ><bar  >foobar</bar></foo>'
    actual = tagz{ 
      foo_{ 
        bar_{ 'foobar' }
      }
    }
    assert_equal expected, actual
  end

  def test_060
    expected = '<foo key="value"  ><bar a="b"  >foobar</bar></foo>'
    actual = tagz{ 
      foo_('key' => 'value'){ 
        bar_(:a => :b){ 'foobar' }
      }
    }
    assert_equal expected, actual
  end

  def test_070
    expected = '<foo  /><bar  />'
    actual = tagz{ 
      foo_{} + bar_{}
    }
    assert_equal expected, actual
  end

=begin
  def test_080
    assert_raises(Tagz::NotOpen) do
      foo_{ _bar }
    end
  end
  def test_090
    assert_raises(Tagz::NotOpen) do
      _foo
    end
  end
  def test_100
    assert_nothing_raised do
      foo_
      _foo
    end
  end
=end

  def test_110
    expected = '<foo  ><bar  >foobar</bar></foo>'
    actual = tagz{ 
      foo_{ 
        bar_{ 'foobar' }
        'this content is ignored because the block added content'
      }
    }
    assert_equal expected, actual
  end

  def test_120
    expected = '<foo  ><bar  >foobar</bar><baz  >barfoo</baz></foo>'
    actual = tagz{ 
      foo_{ 
        bar_{ 'foobar' }
        baz_{ 'barfoo' }
      }
    }
    assert_equal expected, actual
  end

  def test_121
    expected = '<foo  ><bar  >foobar</bar><baz  >barfoo</baz></foo>'
    actual = tagz{ 
      foo_{ 
        bar_{ 'foobar' }
        baz_{ 'barfoo' }
      }
    }
    assert_equal expected, actual
  end

  def test_130
    expected = '<foo  >a<bar  >foobar</bar>b<baz  >barfoo</baz></foo>'
    actual = tagz{ 
      foo_{ |t|
        t << 'a'
        bar_{ 'foobar' }
        t << 'b'
        baz_{ 'barfoo' }
      }
    }
    assert_equal expected, actual
  end

  def test_140
    expected = '<foo  ><bar  >baz</bar></foo>'
    actual = tagz{ 
      foo_{
        bar_ << 'baz'
        _bar
      }
    }
    assert_equal expected, actual
  end

  def test_150
    expected = '<foo  ><bar  >bar<baz  >baz</baz></bar></foo>'
    actual = tagz{ 
      foo_{
        bar_ << 'bar'
          tag = baz_
          tag << 'baz'
          _baz
        _bar
      }
    }
    assert_equal expected, actual
  end

  def test_160
    expected = '<foo  >a<bar  >b</bar></foo>'
    actual = tagz{ 
      foo_{ |foo|
        foo << 'a'
        bar_{ |bar|
          bar << 'b'
        }
      }
    }
    assert_equal expected, actual
  end

  def test_170
    expected = '<html  ><body  ><ul  ><li  >a</li><li  >b</li><li  >c</li></ul></body></html>'
    @list = %w( a b c )
    actual = tagz{ 
      html_{
        body_{
          ul_{
            @list.each{|elem| li_{ elem } }
          }
        }
      }
    }
    assert_equal expected, actual
  end

  def test_180
    expected = '<html  ><body  >42</body></html>'
    actual = tagz{ 
      html_{
        b = body_
          b << 42
        _body
      }
    }
    assert_equal expected, actual
  end

  def test_190
    expected = '<html  ><body  >42</body></html>'
    actual = tagz{ 
      html_{
        body_
          tagz << 42 ### tagz is always the current tag!
        _body
      }
    }
    assert_equal expected, actual
  end

  def test_200
    expected = '<html  ><body  >42</body></html>'
    actual = tagz{ 
      html_{
        body_{
          tagz << 42 ### tagz is always the current tag!
        }
      }
    }
    assert_equal expected, actual
  end

  def test_210
    expected = '<html  ><body  >42</body></html>'
    actual = tagz{ 
      html_{
        body_{ |body|
          body << 42
        }
      }
    }
    assert_equal expected, actual
  end

=begin
  def test_220
    expected = '<html  ><body  >42</body></html>'
    actual = tagz{ 
      'html'.tag do
       'body'.tag do
          42
        end
      end
    }
    assert_equal expected, actual
  end
=end

  def test_230
    expected = '<html  ><body  ><div k="v"  >content</div></body></html>'
    actual = tagz{ 
      html_{
        body_{
          div_(:k => :v){ "content" }
        }
      }
    }
    assert_equal expected, actual
  end

  def test_240
    expected = '<html  ><body  ><div k="v"  >content</div></body></html>'
    actual = tagz{ 
      html_{
        body_{
          div_ "content", :k => :v
        }
      }
    }
    assert_equal expected, actual
  end

  def test_241
    expected = '<html  ><body  ><div k="v"  >content</div></div></body></html>'
    actual = tagz{ 
      html_{
        body_{
          div_ "content", :k => :v 
          _div
        }
      }
    }
    assert_equal expected, actual
  end

  def test_250
    expected = '<html  ><body  ><div k="v"  >content and more content</div></body></html>'
    actual = tagz{ 
      html_{
        body_{
          div_("content", :k => :v){ ' and more content' }
        }
      }
    }
    assert_equal expected, actual
  end

  def test_260
    expected = '<html  ><body  ><div k="v"  >content</div></body></html>'
    actual = tagz{ 
      html_{
        body_{
          div_ :k => :v 
          tagz << "content"
          _div
        }
      }
    }
    assert_equal expected, actual
  end

  def test_270
    expected = '<html  ><body  ><div k="v"  >content</div></body></html>'
    actual = tagz{ 
      html_{
        body_{
          div_ :k => :v 
          tagz << "content"
          _div
        }
      }
    }
    assert_equal expected, actual
  end

  def test_280
    expected = 'content'
    actual = tagz{ 
      tagz << "content"
    }
    assert_equal expected, actual
  end

  def test_290
    expected = 'foobar'
    actual = tagz{ 
      tagz {
        tagz << 'foo' << 'bar'
      }
    }
    assert_equal expected, actual
  end

=begin
  def test_300
    expected = 'foobar'
    actual = tagz{ 
      tagz{ tagz 'foo', 'bar' }
    }
    assert_equal expected, actual
  end
=end

  def test_310
    expected = '<html  ><body  ><div k="v"  >foobar</div></body></html>'
    actual = tagz{ 
      html_{
        body_{
          div_! "foo", "bar", :k => :v 
        }
      }
    }
    assert_equal expected, actual
  end

  def test_320
    expected = '<html  ><body  ><a href="a"  >a</a><span  >|</span><a href="b"  >b</a><span  >|</span><a href="c"  >c</a></body></html>'
    links = %w( a b c )
    actual = tagz{ 
      html_{
        body_{
          links.map{|link| e(:a, :href => link){ link }}.join e(:span){ '|' } 
        }
      }
    }
    assert_equal expected, actual
  end

  def test_330
    expected = '<a  ><b  ><c  >'
    actual = tagz{ 
      tagz {
        a_
        b_
        c_
      }
    }
    assert_equal expected, actual
  end

  def test_340
    expected = '<a  ><b  ><c  ></a>'
    actual = tagz{ 
      a_ {
        b_
        c_
      }
    }
    assert_equal expected, actual
  end

  def test_350
    expected = '<a  ><b  ><c  >content</c></a>'
    actual = tagz{ 
      a_ {
        b_
        c_ "content"
      }
    }
    assert_equal expected, actual
  end

  def test_360
    expected = '<a  ><b  >content</b><c  ><d  >more content</d></a>'
    actual = tagz{ 
      a_ {
        b_ "content"
        c_
        d_ "more content"
      }
    }
    assert_equal expected, actual
  end

=begin
  def test_370
    expected = 'ab'
    actual = tagz{ 
      re = 'a'
      re << tagz{'b'}
      re
    }
    assert_equal expected, actual
  end
=end

  def test_380
    expected = 'ab'
    actual = tagz{ 
      tagz{ 'a' } + tagz{ 'b' } 
    }
    assert_equal expected, actual
  end
end
