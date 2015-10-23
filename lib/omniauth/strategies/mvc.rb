require 'omniauth/strategies/oauth2'
require 'json'

module OmniAuth
  module Strategies
    class MVC < OmniAuth::Strategies::OAuth2
      class NoAuthorizationCodeError < StandardError; end
    # class MVC < OmniAuth::Strategies::OAuth
      option :name, 'mvc'

      option :client_options, {
        site: 'https://www.mvc-online.com',
        authorize_path: '/oauth/authorize'
      }

      uid { access_token.params[:id] }

      info do
        {
          # :nickname => raw_info['userscreenname'],
          :name => raw_info['userscreenname'],
          :email => raw_info["email"]
          # :location => raw_info['location'],
          # :image => image_url,
          # :description => raw_info['description'],
          # :urls => {
          #   'Website' => raw_info['url'],
          #   'Twitter' => "https://twitter.com/#{raw_info['screen_name']}",
          # }
        }
      end

      extra do
        skip_info? ? {} : { :raw_info => raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get('me', info_options).parsed || {}
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
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

    end
  end
end

OmniAuth.config.add_camelization 'mvc', 'MVC'