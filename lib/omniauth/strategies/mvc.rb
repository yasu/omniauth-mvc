require 'omniauth/strategies/oauth2'
require 'json'

module OmniAuth
  module Strategies
    class MVC < OmniAuth::Strategies::OAuth2
      class NoAuthorizationCodeError < StandardError; end
      option :name, 'mvc'

      option :client_options, {
        site: 'https://www.mvc-online.com',
        authorize_path: '/oauth/authorize'
      }

      option :authorize_options, [:scope, :display, :auth_type]

      uid { access_token.params[:id] }

      info do
        {
          :name              => raw_info['screen_name'],
          :email             => raw_info['email'],
          :location          => raw_info['location'],
          :profile_image_url => raw_info['profile_image_url'],
          :urrent_user_url   => raw_info['urrent_user_url']
        }
      end

      extra do
        skip_info? ? {} : { :raw_info => raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get('api/me', info_options).parsed || {}
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end

      def info_options
        params = {:appsecret_proof => appsecret_proof}
        params.merge!({:fields => (options[:info_fields] || 'name,email')})
        params.merge!({:locale => options[:locale]}) if options[:locale]

        { :params => params }
      end

      alias :old_request_phase :request_phase

      def request_phase
        %w[force_login lang screen_name].each do |v|
          if request.params[v]
            options[:authorize_params][v.to_sym] = request.params[v]
          end
        end

        %w[x_auth_access_type].each do |v|
          if request.params[v]
            options[:request_params][v.to_sym] = request.params[v]
          end
        end

        if options[:use_authorize] || request.params['use_authorize'] == 'true'
          options[:client_options][:authorize_path] = '/oauth/authorize'
        else
          options[:client_options][:authorize_path] = '/oauth/authenticate'
        end

        old_request_phase
      end

      def callback_url
        if @authorization_code_from_signed_request_in_cookie
          ''
        else
          # Fixes regression in omniauth-oauth2 v1.4.0 by https://github.com/intridea/omniauth-oauth2/commit/85fdbe117c2a4400d001a6368cc359d88f40abc7
          options[:callback_url] || (full_host + script_name + callback_path)
        end
      end

      def access_token_options
        options.access_token_options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
      end

      # You can pass +display+, +scope+, or +auth_type+ params to the auth request, if you need to set them dynamically.
      # You can also set these options in the OmniAuth config :authorize_params option.
      #
      # For example: /auth/facebook?display=popup
      def authorize_params
        super.tap do |params|
          %w[display scope auth_type].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

      def appsecret_proof
        @appsecret_proof ||= OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, client.secret, access_token.token)
      end
    end
  end
end

OmniAuth.config.add_camelization 'mvc', 'MVC'

module OAuth2
  class Error < StandardError
    attr_reader :response, :code, :description

    # standard error values include:
    # :invalid_request, :invalid_client, :invalid_token, :invalid_grant, :unsupported_grant_type, :invalid_scope
    def initialize(response)
      response.error = self
      @response = response

      message = []

      if response.parsed.is_a?(Hash)
        @code = response.parsed['error']
        @description = response.parsed['error_description']
        message << "#{@code}: #{@description}"
      end

      message << response.body.force_encoding("UTF-8")

      super(message.join("\n"))
    end
  end
end