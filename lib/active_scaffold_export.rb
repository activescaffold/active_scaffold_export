# frozen_string_literal: true

require 'active_scaffold_export/engine'
require 'active_scaffold_export/extensions'
require 'active_scaffold_export/version'

module ActiveScaffoldExport
  def self.root
    "#{File.dirname(__FILE__)}/.."
  end
  autoload :Column, 'active_scaffold_export/column.rb'
end

ActiveScaffold.stylesheets << 'active_scaffold_export'
ActiveScaffold.set_element :export_option, tag: :div, attributes: {class: 'export-option'}
ActiveScaffold.set_element :export_option_row, tag: :div, attributes: {class: 'export-option-row'}
