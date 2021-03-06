require 'yaml'

module RackFlags

  class Config
    attr_reader :flags
    
    def self.load( yaml_path )
      flags = YAML.load( File.read( yaml_path ) )
      new( flags )
    end

    def initialize(flag_config)
      flag_config ||= {}

      @flags = flag_config.map do |flag_name, flag_details| 
        base_flag_from_config_entry(flag_name,flag_details)
      end
    end

    private

    def base_flag_from_config_entry( name, details )
      symbolized_details = symbolize_keys( details )
      BaseFlag.new( 
                   name.to_sym,
                   symbolized_details.fetch( :description ,""),
                   symbolized_details.fetch( :default ,false)
                  )
    end

    def symbolize_keys(hash)
      hash.inject({}) do |symbolized_hash, (key, value)|
        symbolized_hash[key.to_sym] = value
        symbolized_hash
      end
    end
    
  end

end