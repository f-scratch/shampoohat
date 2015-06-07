# Encoding: utf-8
#
# Authors:: api.dklimkin@gmail.com (Danial Klimkin)
#
# Copyright:: Copyright 2012, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# This module manages OAuth2.0 JWT authentication.

require 'faraday'
require 'signet/oauth_2/client'

require 'shampoohat/auth/base_handler'
require 'shampoohat/errors'

module Shampoohat
  module Auth

    # Credentials class to handle OAuth2.0 authentication.
    class OAuth2JwtHandler < Shampoohat::Auth::BaseHandler

      OAUTH2_CONFIG = {
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token'
      }

      # Initializes the OAuthHandler2 with all the necessary details.
      #
      # Args:
      # - config: Config object with library configuration
      # - scope: OAuth authorization scope
      #
      def initialize(config, scope)
        super(config)
        @scope, @client = scope, nil
      end

      # Invalidates the stored token if the required credential has changed.
      def property_changed(prop, value)
        oauth2_keys =
            [:oauth2_issuer, :oauth2_secret, :oauth2_keyfile, :oauth2_key]
        @client = nil if oauth2_keys.include?(prop)
      end

      def handle_error(error)
        # TODO: Add support.
        get_logger().error(error)
        raise error
      end

      # Generates auth string for OAuth2.0 JWT method of authentication.
      #
      # Args:
      # - credentials: credentials set for authorization
      #
      # Returns:
      # - Authentication string
      #
      def auth_string(credentials)
        token = get_token(credentials)
        return ::Signet::OAuth2.generate_bearer_authorization_header(
                    token[:access_token])
      end

      # Overrides base get_token method to account for the token expiration.
      def get_token(credentials = nil)
        token = super(credentials)
        token = refresh_token! if !@client.nil? && @client.expired?
        return token
      end

      # Refreshes access token from refresh token.
      def refresh_token!()
        return nil if @token.nil? or @token[:refresh_token].nil?
        @client.refresh!
        @token = token_from_client(@client)
        return @token
      end

      private

      # Auxiliary method to validate the credentials for JWT authentication.
      #
      # Args:
      # - credentials: a hash with the credentials for the account being
      #   accessed
      #
      # Raises:
      # - Shampoohat::Errors::AuthError if validation fails
      #
      def validate_credentials(credentials)
        if @scope.nil?
          raise Shampoohat::Errors::AuthError, 'Scope is not specified.'
        end

        if credentials.nil?
          raise Shampoohat::Errors::AuthError, 'No credentials supplied.'
        end

        if credentials[:oauth2_issuer].nil?
          raise Shampoohat::Errors::AuthError,
              'Issuer is not included in the credentials.'
        end

        if credentials[:oauth2_secret].nil?
          raise Shampoohat::Errors::AuthError,
              'Key secret is not included in the credentials.'
        end

        if credentials[:oauth2_key].nil? && credentials[:oauth2_keyfile].nil?
          raise Shampoohat::Errors::AuthError,
              'Either key or key file must be provided for OAuth2 JWT.'
        end

        if credentials[:oauth2_key] && credentials[:oauth2_keyfile]
          raise Shampoohat::Errors::AuthError,
              'Both JWT key and key file provided, only one can be used.'
        end

        if credentials[:oauth2_key] &&
            !credentials[:oauth2_key].kind_of?(OpenSSL::PKey::RSA)
          raise Shampoohat::Errors::AuthError,
              'OAuth2 JWT key provided must be of type OpenSSL::PKey::RSA.'
        end

        if credentials[:oauth2_keyfile] &&
            !File.file?(credentials[:oauth2_keyfile])
          raise Shampoohat::Errors::AuthError,
              "Key file '%s' does not exist or not a file." %
              credentials[:oauth2_keyfile]
        end
      end

      # Auxiliary method to generate an authentication token for logging via
      # the OAuth2.0 API.
      #
      # Args:
      # - credentials: a hash with the credentials for the account being
      #   accessed
      #
      # Returns:
      # - The auth token for the account (as an AccessToken)
      #
      # Raises:
      # - Shampoohat::Errors::AuthError if authentication fails
      # - Shampoohat::Errors::OAuthVerificationRequired if OAuth verification
      #   code required
      #
      def create_token(credentials)
        validate_credentials(credentials)
        @client ||= create_client(credentials)
        @client.fetch_access_token!()
        return token_from_client(@client)
      end

      # Creates a Signet client based on credentials.
      def create_client(credentials)
        credentials = load_oauth2_jwt_credentials(credentials)
        oauth_options = OAUTH2_CONFIG.merge({
            :issuer => credentials[:oauth2_issuer],
            :signing_key => credentials[:oauth2_key],
            :person => credentials[:oauth2_prn],
            :scope => @scope,
        })
        return Signet::OAuth2::Client.new(oauth_options)
      end

      # Loads JWT key if configured with a filename.
      def load_oauth2_jwt_credentials(credentials)
        return credentials unless credentials.include?(:oauth2_keyfile)
        key_file = File.read(credentials[:oauth2_keyfile])
        key_secret = credentials[:oauth2_secret]
        key = OpenSSL::PKCS12.new(key_file, key_secret).key
        result = credentials.merge({:oauth2_key => key})
        result.delete(:oauth2_keyfile)
        return result
      end

      # Create a token Hash from a client.
      def token_from_client(client)
        return nil if client.access_token.nil?
        return {
          :access_token => client.access_token,
          :issued_at => client.issued_at,
          :expires_in => client.expires_in,
          :id_token => client.id_token
        }
      end
    end
  end
end
