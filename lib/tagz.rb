unless defined? Tagz

  require 'cgi'

  module Tagz
    unless defined?(Tagz::VERSION)
      Tagz::VERSION = [
        Tagz::VERSION_MAJOR = 1,
        Tagz::VERSION_MINOR = 0,
        Tagz::VERSION_TEENY = 0 
      ].join('.')
      def Tagz.version() Tagz::VERSION end
    end

    class Fragment < ::String
      def << other
        super other.to_s
        self
      end

      def + other
        self.dup << other
      end
    end

    class Element < ::String
      def Element.attributes options
        unless options.empty?
          ' ' << 
            options.map do |key, value|
              key = CGI.escapeHTML key.to_s
              value = CGI.escapeHTML value.to_s
              if value =~ %r/"/
                raise ArgumentError, value if value =~ %r/'/
                value = "'#{ value }'"
              else
                raise ArgumentError, value if value =~ %r/"/
                value = "\"#{ value }\""
              end
              [key, value].join('=')
            end.join(' ')
        else
          ''
        end
      end

      attr 'name'

      def initialize name, *argv, &block
        options = {}
        content = []

        argv.each do |arg|
          case arg
            when Hash
              options.update arg
            else
              content.push arg
          end
        end

        content.push block.call if block
        content.compact!

        @name = name.to_s

        if content.empty?
          replace "<#{ @name }#{ Element.attributes options }>"
        else
          replace "<#{ @name }#{ Element.attributes options }>#{ content.join }</#{ name }>"
        end
      end
    end

    def Tagz.export *methods 
      methods.flatten.compact.uniq.each do |m|
        module_function m
      end
    end

    def Tagz.<< other
      Tagz.tagz << other
      self
    end

  private

    def tagz &block
      if block
        if not defined?(@tagz) or @tagz.nil?
          @tagz = Fragment.new
          top = true
        end
        begin
          size = @tagz.size
          value = instance_eval(&block)
          @tagz << value unless(Fragment === value or @tagz.size > size)
          @tagz
        ensure
          @tagz = nil if top
        end
      else
        @tagz ||= Fragment.new
      end
    end

    def tagz__ name, *argv, &block
      options = {}
      content = []

      argv.each do |arg|
        case arg
          when Hash
            options.update arg
          else
            content.push arg
        end
      end

      unless options.empty?
        attributes = ' ' << 
          options.map do |key, value|
            key = CGI.escapeHTML key.to_s
            value = CGI.escapeHTML value.to_s
            if value =~ %r/"/
              raise ArgumentError, value if value =~ %r/'/
              value = "'#{ value }'"
            else
              raise ArgumentError, value if value =~ %r/"/
              value = "\"#{ value }\""
            end
            [key, value].join('=')
          end.join(' ')
      else
        attributes = ''
      end

      tagz << "<#{ name }#{ attributes }>"

      if content.empty?
        if block
          size = tagz.size
          value = block.call(tagz)
          unless value
            tagz[-1] = "/>"
          else
            tagz << value.to_s unless(Fragment === value or tagz.size > size)
            tagz << "</#{ name }>"
          end
        end
      else
        content.each{|c| tagz << c.to_s unless Fragment === c}
        if block
          size = tagz.size
          value = block.call(tagz)
          tagz << value.to_s unless(Fragment === value or tagz.size > size)
        end
        tagz << "</#{ name }>"
      end

      tagz
    end

    def __tagz tag, *a, &b
      tagz << "</#{ tag }>"
    end

    def method_missing m, *a, &b
      return super unless @tagz
      case m.to_s
        when %r/^(.*[^_])_(!)?$/o
          m, bang = $1, $2
          unless bang
            tagz__(m, *a, &b)
          else
            tagz__(m, *a){}
          end
        when %r/^_([^_].*)$/o
          m = $1 
          __tagz(m, *a, &b)
        when 'tag', 'e'
          Element.new(*a, &b)
        else
          super
      end
    end

    export %w( tagz tagz__ __tagz method_missing )
  end

  def Tagz *argv, &block
    if argv.empty? and block.nil?
      ::Tagz
    else
      Tagz.tagz(*argv, &block)
    end
  end

end
