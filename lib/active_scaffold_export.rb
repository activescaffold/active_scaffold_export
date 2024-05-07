require 'active_scaffold_export/engine'
require 'active_scaffold_export/version'

module ActiveScaffoldExport
  def self.root
    File.dirname(__FILE__) + "/.."
  end
end
