# Encoding: utf-8

require 'shampoohat/savon_headers/base_header_handler'

module Shampoohat
  module SavonHeaders
    class YahooHeaderHandler < BaseHeaderHandler

      private

      def generate_headers(request, soap)
        soap.header = { "ns1:RequestHeader" => @login_info }
      end
    end
  end
end
