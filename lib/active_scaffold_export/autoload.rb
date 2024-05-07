module ActiveScaffold
  module Actions
    ActiveScaffold.autoload_subdir('actions', self, ActiveScaffoldExport.root + '/lib')
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self, ActiveScaffoldExport.root + '/lib')
  end

  module Helpers
    ActiveScaffold.autoload_subdir('helpers', self, ActiveScaffoldExport.root + '/lib')
  end
end
