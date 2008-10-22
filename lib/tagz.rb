unless defined? Tagz

  require 'cgi'

  module Tagz
    unless defined?(Tagz::VERSION)
      Tagz::VERSION = [
        Tagz::VERSION_MAJOR = 4,
        Tagz::VERSION_MINOR = 2,
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

    module Globally
    private
      include Tagz
      def method_missing m, *a, &b 
        tagz{ super }
      end
    end

    def Tagz.globally
      Globally
    end

  private

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
          if NilClass == value
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
          @tagz.to_s
        ensure
          @tagz = nil if top
        end
      else
        @tagz if defined? @tagz
      end
    end

    def method_missing m, *a, &b
      if not Globally === self
        unless defined?(@tagz) and @tagz
          begin
            super
          ensure
            $!.set_backtrace caller(skip=1) if $!
          end
        end
      end
      
      case m.to_s
        when %r/^(.*[^_])_(!)?$/o
          m, bang = $1, $2
          b ||= lambda{} if bang
          tagz{ tagz__(m, *a, &b) }
        when %r/^_([^_].*)$/o
          m = $1 
          tagz{ __tagz(m, *a, &b) }
        when 'e'
          Element.new(*a, &b)
        when '__'
          tagz{ tagz << "\n" }
        else
          begin
            super
          ensure
            $!.set_backtrace caller(skip=1) if $!
          end
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

  if defined?(Rails)
    ActionView::Base.send(:include, Tagz.globally)
    ActionController::Base.send(:include, Tagz)
  end

end
