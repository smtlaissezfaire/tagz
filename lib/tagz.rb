module Tagz
  Tagz::VERSION = '0.0.4' unless defined? Tagz::VERSION
  def self.version() VERSION end

  class NotOpen < StandardError; end
  class StillOpen < StandardError; end

  class << self
    def default_non_container_tag_list
      # http://www.w3schools.com/xhtml/xhtml_ref_byfunc.asp
      %w[
        br hr input img area base basefont
      ]
    end

    def non_container_tag_list *argv 
      if argv.first
        @non_container_tag_list = [argv.first].flatten.uniq.map{|arg| arg.to_s}
        @non_container_tags = @non_container_tag_list.inject(Hash.new){|h,k| h.update k => true}
        @non_container_tag_list
      else
        if defined?(@non_container_tag_list) and @non_container_tag_list
          @non_container_tag_list
        else
          non_container_tag_list default_non_container_tag_list
          @non_container_tag_list
        end
      end
    end

    def non_container_tags
      if defined?(@non_container_tags) and @non_container_tags
        @non_container_tags
      else
        non_container_tag_list
        @non_container_tags
      end
    end

    def container? tag
      not(non_container_tags[tag.to_s] or false)
    end

    def emtpy? tag
      not container?(tag)
    end
  end

  module Fragment
    attr_accessor 'tag' 
    attr_accessor 'open' 
    attr_accessor 'added' 
    attr_accessor 'created_at'
    alias_method 'open?', 'open'

    def self.new str='', tag='', options = {}
      return str if Fragment === str
      str.extend Fragment
      str.tag = tag.to_s
      str.stack << tag.to_s 
      str.open = true 
      str.added = { str.object_id => true }
      options.each{|k,v| str.send "#{ k }=", v}
      str.created_at = caller
      str
    end

    def stack 
      @stack ||= []
    end

    def push fragment
      if Fragment === fragment
        stack.push fragment.tag
      end
    end

    def pop
      stack.pop
    end

    def closes? other
      tag.to_s == other.tag.to_s
    end

    def << content
      super content.to_s
    end

    def add fragment
      push fragment
      oid = fragment.object_id
      self << fragment unless added[oid]
      self
    ensure
      added[oid] = true
    end
  end


  module Abilities
  private
    def tagz *argv, &block
      stack = __tag_stack__
      top = stack.last
      size = stack.size

      unless block
        top ||= Fragment()
        if argv.empty?
          top
        else
          string = argv.join
          top.add string 
          string
        end
      else
        obj = Tagz === self ? self : clone.instance_eval{ extend Tagz; self }
        stack << (top=Fragment())
        top = stack.last
        tid = top.object_id

        string = obj.instance_eval(&block)

        until stack.last.object_id == tid
          pop = stack.pop
          last = stack.last
          last.add pop 
        end

        top = stack.pop

        content_was_added = top.size > 0
        top.add string unless content_was_added

        top
      end
    end

    def method_missing m, *a, &b
      case m.to_s
        when %r/^(.*[^_])_(!)?$/o
          m, bang = $1, $2
          unless bang
            __tag_start__ m, *a, &b
          else
            __tag_start__(m, *a){}
          end
        when %r/^_([^_].*)$/o
          m = $1 
          __tag_stop__ m, *a, &b
        else
          super
      end
    end

    def __tag_stack__
      @__tag_stack__ ||= []
    end

    def __tag_attrs__ attrs = {}
      return nil if attrs.empty?
      ( 42 - 10 ).chr <<
        case attrs
          when Hash
            attrs.map{|k,v| "#{ k }=#{ v.to_s.inspect }"}.join(" ")
          else
            attrs.to_s
        end
    end

    def __tag_start__ *argv, &block
      tag = argv.shift

      case argv.size
        when 0                      # no attrs, no content
          attrs = {}
          content = nil
        when 1                      # string content
          case argv.first
            when Hash
              attrs = argv.shift 
              content = nil 
            else
              if block
                attrs = argv.shift 
                content = nil 
              else
                content = argv.shift 
                attrs = {}
              end
          end
        when 2                      # string attrs, string content OR string content, hash attrs
          case argv.last
            when Hash
              attrs = argv.last
              content = argv.first.to_s
            else
              attrs = argv.first
              content = argv.last.to_s
          end
        else                       # string attrs, string content(s) OR string content(s), hash attrs
          case argv.last
            when Hash
              attrs = argv.last
              content = argv[0..-2].join
            else
              attrs = argv.first
              content = argv[1..-1].join
          end
      end

      if content and block
        b = block and block = lambda{ "#{ content }#{ b.call }" }
      end

      if content and block.nil?
        #block = lambda{ content }
      end

      stack = __tag_stack__

      if block.nil?
        start = Fragment( "<#{ tag }#{ __tag_attrs__ attrs }  >#{ content }", tag )
        stack << start 
        start
      else
        ### we reserve two bytes ( 0.chr 0.chr ) to avoid massive data shift/copy
        start = Fragment( "<#{ tag }#{ __tag_attrs__ attrs } #{ 0.chr }#{ 0.chr }", tag )
        stack << start 
        size = start.size
        pos = ( (size - 2) .. (size - 1) )
        top = stack.last
        tid = top.object_id
        ssize = stack.size
        

        content = block.call top
        content_was_added = size < start.size


        ### handle dangling tags
        if stack.size > ssize 
          i = ssize
          while((opentag = stack[i]))
            top.add opentag
            i += 1
          end
          stack.pop until stack.size == ssize
        end

### TODO we could raise an error
=begin
        until stack.last.object_id == tid
          begin
            last = stack.last
            ne = last.created_at[3] 
            raise StillOpen, "<#{ last.tag }> @ '#{ ne }'"
          ensure
            stack.clear
          end
        end
=end
        
        if content or Tagz.container?(tag)
          top[pos] = ' >'
          top.add content unless content_was_added
          stop = Fragment( "</#{ tag }>", tag, :open => false )
          top.add stop
          top.open = false
        else
          top[pos] = '/>'
          top.open = false
        end

        content = stack.pop

        top = stack.last
        if top and top.open?
          top.add content
        end

        content
      end
    end

    def __tag_stop__ tag
      stack = __tag_stack__
      top = stack.last
      stop = Fragment( "</#{ tag }>", tag, :open => false )
      if top
        if stop.closes?(top)
          top.add stop
          top.open = false
          content = stack.pop
          top = stack.last
          top.add content if top and top.open?
          content
        else
          raise NotOpen, tag.to_s
        end
      else
        raise NotOpen, tag.to_s
      end
    end

    def Fragment(*a, &b) Fragment.new(*a, &b) end

    def element tag, *a, &b
      __tag_stack__ << (top=Fragment())
      __tag_start__ tag, *a, &b
      __tag_stack__.pop
    end
    alias_method "e", "element"

    def element_ tag, *a, &b
      __tag_stack__ << (top=Fragment())
      __tag_start__ tag, *a, &b
      __tag_stack__.pop
    end
    alias_method "e_", "element_"

    def _element tag, *a, &b
      __tag_stack__ << (top=Fragment())
      __tag_stop__ tag, *a, &b
      __tag_stack__.pop
    end
    alias_method "_e", "_element"

    def element! tag, *a, &b
      b ||= lambda{}
      __tag_stack__ << (top=Fragment())
      __tag_start__ tag, *a, &b
      __tag_stack__.pop
    end
    alias_method "e!", "element!"

    def xhtml_ which = :transitional, *a, &b
      decl = 
%Q|<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-#{ which }.dtd'>|
      attrs = {}
      attrs.update 'xmlns' => 'http://www.w3.org/1999/xhtml',
                   'xml:lang' => 'en'
      decl << html_(attrs, &b)
    end
  end

  def self.included other
    other.module_eval{ include Abilities }
  end

  def self.extend_object other
    other.extend Abilities 
  end

  class ::String
    include Tagz 
    def tag *a, &b
      tagz{ __tag_start__ self, *a, &b }
    end
    def tag_ *a, &b
      tagz{ __tag_start__ self, *a, &b }
    end
    def _tag *a, &b
      tagz{ __tag_start__ self, *a, &b }
    end
    def tag! *a
      tagz{ __tag_start__(self, *a){} }
    end
  end

  class ::Symbol
    include Tagz 
    def tag *a, &b
      tagz{ __tag_start__ self, *a, &b }
    end
    def tag_ *a, &b
      tagz{ __tag_start__ self, *a, &b }
    end
    def _tag *a, &b
      tagz{ __tag_start__ self, *a, &b }
    end
    def tag! *a
      tagz{ __tag_start__(self, *a){} }
    end
  end
end

class Object
  def Tagz &block
    const = Object.const_get :Tagz
    if block
      if const === self
        this = self
      else
        this = eval('self', block).dup
        this.send :extend, Tagz
      end
      this.send :tagz, &block
    else
      const
    end
  end
end

require File.join(File.dirname(__FILE__), 'tagz', 'rails') if defined? Rails
