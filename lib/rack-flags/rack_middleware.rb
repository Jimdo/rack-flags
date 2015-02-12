module RackFlags
  class RackMiddleware
    ENV_KEY = 'x-rack-flags.flag-reader'

    def initialize( app, args )
      @app = app
      @disable_config_caching = args.fetch(:disable_config_caching, false)
      @expose_header = args.fetch(:expose_header, 'X-Labs-Features')
      @yaml_path = args.fetch( :yaml_path ){ raise ArgumentError.new( 'yaml_path must be provided' ) }
    end

    def call( env )
      overrides = CookieCodec.new.overrides_from_env( env )
      reader = Reader.new( config.flags, overrides )
      env[ENV_KEY] = reader

      status, headers, body = @app.call(env)

      flags_parts = reader.base_flags.keys.collect do |flag_name|
        "#{flag_name}=#{reader.on?(flag_name)}"
      end
      headers[@expose_header] = flags_parts.join('; ') unless @expose_header == false

      [status, headers, body]
    end

    private
    def config
      @config = nil if @disable_config_caching
      @config ||= Config.load(@yaml_path)
    end
  end
end
