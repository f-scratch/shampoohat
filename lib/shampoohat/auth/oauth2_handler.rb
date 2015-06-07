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
# This module manages OAuth2.0 authentication.

require 'faraday'
require 'signet/oauth_2/client'

require 'shampoohat/auth/base_handler'
require 'shampoohat/errors'

module Shampoohat
  module Auth

    # Credentials class to handle OAuth2.0 authentication.
    class OAuth2Handler < Shampoohat::Auth::BaseHandler
      OAUTH2_CONFIG = {
          :authorization_uri =>
            'https://accounts.google.com/o/oauth2/auth',
          :token_credential_uri =>
            'https://accounts.google.com/o/oauth2/token'
      }
      DEFAULT_CALLBACK = 'urn:ietf:wg:oauth:2.0:oob'

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
        oauth2_keys = [:oauth2_client_id, :oauth2_client_secret, :oauth2_token]
        if oauth2_keys.include?(prop)
          @token, @client = nil, nil
        end
      end

      def handle_error(error)
        # TODO: Add support.
        get_logger().error(error)
        raise error
      end

      # Generates auth string for OAuth2.0 method of authentication.
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
        begin
          @client.refresh!
        rescue Signet::AuthorizationError => e
          raise Shampoohat::Errors::AuthError.new("OAuth2 token refresh failed",
              e, (e.response.nil?) ? nil : e.response.body)
        end
        @token = token_from_client(@client)
        return @token
      end

      private

      # Auxiliary method to validate the credentials for token generation.
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

        if credentials[:oauth2_client_id].nil?
          raise Shampoohat::Errors::AuthError,
              'Client id is not included in the credentials.'
        end

        if credentials[:oauth2_client_secret].nil?
          raise Shampoohat::Errors::AuthError,
              'Client secret is not included in the credentials.'
        end

        if credentials[:oauth2_token] &&
            !credentials[:oauth2_token].kind_of?(Hash)
          raise Shampoohat::Errors::AuthError,
              'OAuth2 token provided must be a Hash'
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
        return create_token_from_credentials(credentials, @client) ||
            generate_access_token(credentials, @client)
      end

      def create_client(credentials)
        oauth_options = OAUTH2_CONFIG.merge({
            :client_id => credentials[:oauth2_client_id],
            :client_secret => credentials[:oauth2_client_secret],
            :scope => @scope,
            :redirect_uri => credentials[:oauth2_callback] || DEFAULT_CALLBACK,
            :state => credentials[:oauth2_state]
        }).reject {|k, v| v.nil?}
        return Signet::OAuth2::Client.new(oauth_options)
      end

      # Creates access token based on data from credentials.
      #
      # Args:
      # - credentials: a hash with the credentials for the account being
      #   accessed. Has to include :oauth2_token key with a hash value that
      #   represents a stored OAuth2 access token
      # - client: OAuth2 client for the current configuration
      #
      # Returns:
      # - The auth token for the account (as an AccessToken)
      #
      def create_token_from_credentials(credentials, client)
        oauth2_token_hash = credentials[:oauth2_token]
        if !oauth2_token_hash.nil? && oauth2_token_hash.kind_of?(Hash)
          token_data = Shampoohat::Utils.hash_keys_to_str(oauth2_token_hash)
          client.update_token!(token_data)
        end
        return token_from_client(client)
      end

      # Generates new request tokens and authorizes it to get access token.
      #
      # Args:
      # - credentials: a hash with the credentials for the account being
      #   accessed
      # - client: OAuth2 client for the current configuration
      #
      # Returns:
      # - The auth token for the account (as Hash)
      #
      def generate_access_token(credentials, client)
        token = nil
        begin
          verification_code = credentials[:oauth2_verification_code]
          if verification_code.nil? || verification_code.empty?
            uri_options = {
              :access_type => credentials[:oauth2_access_type],
              :approval_prompt => credentials[:oauth2_approval_prompt]
            }.reject {|k, v| v.nil?}
            oauth_url = client.authorization_uri(uri_options)
            raise Shampoohat::Errors::OAuth2VerificationRequired.new(oauth_url)
          else
            client.code = verification_code
            proxy = @config.read('connection.proxy')
            connection = (proxy.nil?) ? nil : Faraday.new(:proxy => proxy)
            client.fetch_access_token!(:connection => connection)
            token = token_from_client(client)
          end
        rescue Signet::AuthorizationError => e
          raise Shampoohat::Errors::AuthError,
              'Authorization error occured: %s' % e
        end
        return token
      end

      # Create a token Hash from a client.
      def token_from_client(client)
        return nil if client.refresh_token.nil? && client.access_token.nil?
        return {
          :access_token => client.access_token,
          :refresh_token => client.refresh_token,
          :issued_at => client.issued_at,
          :expires_in => client.expires_in,
          :id_token => client.id_token
        }
      end
    end
  end
end
