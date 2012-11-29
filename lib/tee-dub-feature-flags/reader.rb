module TeeDub module FeatureFlags

  BaseFlag = Struct.new(:name,:description,:default)

  class Reader
    def initialize( base_flags, overrides )
      @base_flags = load_base_flags( base_flags )
      @overrides = overrides
    end

    def on?(flag_name)
      flag_name = flag_name.to_sym

      return false unless base_flag_exists?( flag_name )

      @overrides.fetch(flag_name) do
        # fall back to defaults
        fetch_base_flag(flag_name).default 
      end
    end

    private

    def load_base_flags( flags )
      Hash[ *flags.map{ |f| [f.name.to_sym, f] }.flatten ]
    end

    def base_flag_exists?( flag_name )
      @base_flags.has_key?( flag_name )
    end

    def fetch_base_flag( flag_name )
      @base_flags.fetch( flag_name ) do
        BaseFlag.new( nil, nil, false ) # if we couldn't find a flag return a Null flag 
      end
    end
  end

end end

