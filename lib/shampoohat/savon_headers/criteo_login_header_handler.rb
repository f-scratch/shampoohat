# Encoding: utf-8

require 'shampoohat/savon_headers/base_header_handler'

module Shampoohat
  module SavonHeaders
    class CriteoLoginHeaderHandler < BaseHeaderHandler

      private

      def generate_headers(request, soap)
        request.headers.delete("SOAPAction")
        # request.headers["Content-Type"] = "soap/xml; charset=utf-8; action='https://advertising.criteo.com/API/v201010/clientLogin'"
      end
    end
  end
end
