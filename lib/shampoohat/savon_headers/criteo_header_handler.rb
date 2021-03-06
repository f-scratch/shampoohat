# Encoding: utf-8

require 'shampoohat/savon_headers/base_header_handler'

module Shampoohat
  module SavonHeaders
    class CriteoHeaderHandler < BaseHeaderHandler

      private

      def generate_headers(request, soap)
        request.headers.delete("SOAPAction")
        soap.header = { "v20:apiHeader" => @header_info }
      end
    end
  end
end
