module Tagz::Rails
  class Renderer
    class Erbout
      def self.for *a, &b
        new *a, &b
      end
      def initialize context
        @context = context
      end
      def nil?
        true
      end
      def method_missing m, *a, &b
        @context.send m, *a, &b
      end
    end

    class Context
      include Tagz

      attr_accessor "__view__"
      attr_accessor "__erbout__"
      attr_accessor "__eol__"

      def self.create view, local_assigns 
        context = new
        context.__view__ = view

        view.assigns.merge(local_assigns).each do |k,v|
          context.instance_variable_set "@#{ k }", v
        end

        local_assigns.each do |k,v|
          context.singleton_class{ define_method(k.to_s){ v } }
        end

        context.instance_variable_set "@content_for_layout", view.instance_variable_get("@content_for_layout")
        context
      end

      def self.render view, local_assigns, *argv
        context = create view, local_assigns

        pushing context do
          source = argv.first
          filename = argv.last

          content_for_lookup = lambda do |*names|
            name = names.shift || :layout
            context.instance_variable_get "@content_for_#{ name }"
          end

          before_ivars = context.instance_variables

            content_for_layout = context.__render__ source, filename, &content_for_lookup

          after_ivars = context.instance_variables

          #new_ivars = ( after_ivars - before_ivars ).delete_if{|ivar| ivar =~ %r/^@(__|content_for_)/o}
          new_ivars = ( after_ivars - before_ivars ).delete_if{|ivar| ivar =~ %r/^@(__)/o}

          new_ivars.each do |ivar|
            key = ivar[1..-1]
            value = context.instance_variable_get ivar
            view.assigns[key] = value
          end

          content_for_layout
        end
      end

      def self.stack
        @stack ||= []
      end

      def self.pushing context
        stack.push context
        begin
          yield
        ensure
          stack.pop
        end
      end

      def self.depth
        stack.size
      end

      def __render__ source, filename
        tagz {
          content_for_layout = eval source.to_s, binding, filename
        }
      end

      def singleton_class &b
        sc = 
          class << self 
            self 
          end  
        b ? sc.module_eval(&b) : sc
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
            __view__.send m, *a, &b
        end
      end

      def flash *a, &b
        __view__.controller.send :flash, *a, &b
      end

      def _erbout
        self.__erbout__ ||= Erbout.for(self)
        #Erbout.for self
      end

      def << s
        __ s; nil 
      end

      def puts *a
        a.each{|elem| self << "#{ elem.to_s.chomp }#{ eol }"}
      end

      def p *a
        a.each{|elem| self << "#{ CGI.escapeHTML elem.inspect }#{ eol }"}
      end

      def print *a
        a.each{|elem| self << elem}
      end

      def eol
        if  __view__.controller.response.content_type =~ %r|text/plain|io
          "\n"
        else
          "<br />"
        end
      end

      def capture *a, &b
        b.call *a
      end

      def content_for(name, &block)
        name, ivar = "content_for_#{ name }", "@content_for_#{ name }"
        value = instance_variable_get(ivar).to_s
        value << capture(&block).to_s
        instance_variable_set ivar, value
        __view__.assigns[name] = value
        nil
      end

    end

    def initialize view
      @view = view
    end

    def render template, local_assigns, path
      (( Context.render @view, local_assigns, template, path )).to_s
    end
  end

  def self.new *a, &b
    Renderer.new *a, &b
  end

  #if defined? ::ActionView and defined? ::ActionView::Base
### TODO - see if this hack can be pulled out
    module ::ActionView # thanks _why !
      class Base
        def render_template(template_extension, template, file_path = nil, local_assigns = {})
          if handler = @@template_handlers[template_extension]
            template ||= read_template_file(file_path, template_extension)
            handler.new(self).render(template, local_assigns, file_path)
          else
            compile_and_render_template(template_extension, template, file_path, local_assigns)
          end
        end
      end
    end
    ::ActionView::Base.register_template_handler 'rb', Tagz::Rails
    ::ActionView::Base.register_template_handler 'tagz', Tagz::Rails
  #end
end
