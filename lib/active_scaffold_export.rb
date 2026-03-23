require 'active_scaffold_export/engine'
require 'active_scaffold_export/version'

module ActiveScaffoldExport
  def self.root
    File.dirname(__FILE__) + "/.."
  end
  autoload 'Column', 'active_scaffold_export/column.rb'
end

module ActiveScaffold
  module Actions
    ActiveScaffold.autoload_subdir('actions', self, File.dirname(__FILE__))
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self, File.dirname(__FILE__))
  end

  module Helpers
    ActiveScaffold.autoload_subdir('helpers', self, File.dirname(__FILE__))
  end
end

ActionView::Base.send(:include, ActiveScaffold::Helpers::ExportHelpers)
ActiveScaffold.stylesheets << 'active_scaffold_export'
ActiveScaffold.ui_elements[:export_option] = {tag: :div, attributes: {class: 'option-wrapper'}}
ActiveScaffold.ui_elements[:export_option_row] = {tag: :div, attributes: {class: 'option-row'}}
