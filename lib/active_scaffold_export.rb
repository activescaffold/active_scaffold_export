ACTIVE_SCAFFOLD_EXPORT_GEM = true
ActiveScaffold rescue throw "should have included ActiveScaffold plug in first.  Please make sure that this plug-in comes alphabetically after the ActiveScaffold plug-in"

require 'active_scaffold_export/engine'
require 'active_scaffold_export/version'

module ActiveScaffoldExport
  def self.root
    File.dirname(__FILE__) + "/.."
  end
  autoload 'Core', 'active_scaffold_export/core.rb'
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
