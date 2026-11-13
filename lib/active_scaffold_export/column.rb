# frozen_string_literal: true

module ActiveScaffoldExport
  module Column
    extend ActiveSupport::Concern

    included do
      attr_accessor :export_options
    end
  end
end
