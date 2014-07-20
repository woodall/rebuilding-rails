require 'erubis'
require 'rulers/file_model'
require 'rack/request'

module Rulers
  class Controller
    include Rulers::Model
    
    def initialize(env)
      @env = env
      @routing_params = {}
    end

    def dispatch(action, routing_params={})
      @routing_params = routing_params
      text = self.send(action)
      if get_response
        st, hd, rs = get_response.to_a
        [st, hd, [rs].flatten]
      else
        [200, {'Content-Type' => 'text/html'},
          [text].flatten]
      end
    end

    def self.action(act, rp = {})
      proc { |e| self.new(e).dispatch(act, rp) }
    end

    def response(text, status = 200, headers = {})
      require 'pry'; binding.pry
      raise "Already responded" if @response
      a = [text].flatten
      @response = Rack::Response.new(a, status, headers)
    end
    
    def get_response
      @response
    end

    def render_response(*args)
      response(render(*args))
    end
    
    def request
      require 'pry'; binding.pry
      @request ||= Rack::Request.new(@env)
    end

    def params
      request.params.merge @routing_params
    end    

    def controller_name
      klass = self.class
      klass = klass.to_s.gsub /Controller$/, ""
      Rulers.to_underscore klass
    end

    def render(view_name, locals = {})
      filename = File.join "app", "views", controller_name, "#{view_name}.html.erb"
      template = File.read filename
      eruby = Erubis::Eruby.new(template)
      eruby.result locals.merge(env: env)
    end

    def env
      @env
    end
  end
end
