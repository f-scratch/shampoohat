# Encoding: utf-8

require 'shampoohat/savon_headers/base_header_handler'

module Shampoohat
  module SavonHeaders
    class NothingHeaderHandler < BaseHeaderHandler

      private

      def generate_headers(request, soap)
      end
    end
  end
end
