require_relative 'spec_helper'

module RackFlags
  describe RackMiddleware do
    def mock_out_config_loading
      stub(Config).load(anything){ OpenStruct.new( flags: {} ) }
    end

    def create_middleware(fake_app = false, additional_args = {})
      args = {yaml_path: 'blah'}.merge additional_args
      fake_app ||= Proc.new {}
      RackMiddleware.new( fake_app, args )
    end

    let( :base_flags ) do
      [
        BaseFlag.new( :usually_on, 'a flag', true )
      ]
    end

    it 'raise an exception if no yaml path is provided' do
      expect {
        RackMiddleware.new( :fake_app, {} )
      }.to raise_error( ArgumentError, 'yaml_path must be provided' )
    end

    it 'loads the config from the specified yaml file' do
      mock(Config).load('some/config/path'){ OpenStruct.new flags: {} }
      middleware = create_middleware(false, yaml_path: 'some/config/path')
      middleware.call({})
    end

    it 'caches configuration by default' do
      mock(Config).load(anything){ OpenStruct.new( flags: {} ) }

      middleware = create_middleware()
      middleware.call({})
      middleware.call({})
    end

    it 'does not cache if specified' do
      mock(Config).load(anything).times(2){ OpenStruct.new( flags: {} ) }

      middleware = create_middleware(false, disable_config_caching: true)
      middleware.call({})
      middleware.call({})
    end

    describe '#call' do
      it 'creates a Reader using the config flags when called' do
        stub(Config).load(anything){ OpenStruct.new( flags: 'fake flags from config' ) }
        mock(Reader).new( 'fake flags from config', anything )

        middleware = create_middleware()
        middleware.call( {} )
      end

      it 'adds the reader to the env' do
        mock_out_config_loading

        mock(Reader).new(anything,anything){ 'fake derived flags' }

        middleware = create_middleware()
        fake_env = {}
        middleware.call( fake_env )
        expect(fake_env[RackMiddleware::ENV_KEY]).to eq 'fake derived flags'
      end

      it 'reads overrides from cookies' do
        mock_out_config_loading

        fake_env = { fake: 'env' }

        fake_cookie_codec = mock( Object.new )
        mock(CookieCodec).new{ fake_cookie_codec }

        fake_cookie_codec.overrides_from_env( fake_env )

        create_middleware().call( fake_env )
      end

      it 'passes the overrides into the reader' do
        mock_out_config_loading

        mock(CookieCodec).new{ stub!.overrides_from_env{'fake overrides'} }
        mock(Reader).new( anything, 'fake overrides' )

        create_middleware().call( {} )
      end

      it 'passes through to downstream app' do
        mock_out_config_loading

        fake_app ||= Proc.new do
          'downstream app response'
        end

        middleware = create_middleware( fake_app )
        middleware_response = middleware.call( {} )

        expect(middleware_response).to eq ["downstream app response", nil, nil]
      end

      it 'add the X-Labs-Features header' do
        mock_out_config_loading

        fake_app ||= Proc.new do
          ['downstream app response', {} ]
        end

        middleware = create_middleware( fake_app, expose_header: true )
        middleware_response, headers = middleware.call( {} )

        expect(headers).to have_key('X-Labs-Features')
      end

      it 'adds all actiuve flag names to the X-Labs-Features header' do
        mock_out_config_loading

        fake_app ||= Proc.new do
          ['downstream app response', {} ]
        end

        any_instance_of(Reader) do |klass|
          stub(klass).active_flags { base_flags }
        end

        middleware = create_middleware( fake_app, expose_header: true )
        middleware_response, headers = middleware.call( {} )

        expect(headers['X-Labs-Features']).to include('usually_on')
      end

      it 'add the #{expose_header} header when expose_header config is present' do
        mock_out_config_loading

        fake_app ||= Proc.new do
          ['downstream app response', {} ]
        end

        middleware = create_middleware( fake_app, expose_header: 'XXX-Another-Feature-Flag-Header' )
        middleware_response, headers = middleware.call( {} )

        expect(headers).to have_key('XXX-Another-Feature-Flag-Header')
      end

      it 'does not add the X-Labs-Features when disabled' do
        mock_out_config_loading

        fake_app ||= Proc.new do
          ['downstream app response', {} ]
        end

        middleware = create_middleware( fake_app, expose_header: false )
        middleware_response, headers = middleware.call( {} )

        expect(headers).not_to have_key('X-Labs-Features')
      end
    end
  end
end
