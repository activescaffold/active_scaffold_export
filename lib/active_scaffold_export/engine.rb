module ActiveScaffoldExport
  class Engine < ::Rails::Engine
    initializer 'active_scaffold_export.routes' do
      ActiveSupport.on_load :active_scaffold_routing do
        self::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection][:show_export] = :get
        self::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection][:export] = :post
      end
    end

    initializer 'active_scaffold_sortable.extensions' do
      require "active_scaffold_export/config/core.rb"
    end
  end
end
