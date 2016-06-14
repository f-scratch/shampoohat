# Encoding: utf-8

require 'shampoohat/savon_headers/base_header_handler'

module Shampoohat
  module SavonHeaders
    # EsmHeaderHandler
    class EsmHeaderHandler < BaseHeaderHandler
      private

      def generate_headers(request, soap)
        request.headers.delete('SOAPAction')
        soap.header = { 'xs:apiHeader' => @header_info }
      end
    end
  end
end
