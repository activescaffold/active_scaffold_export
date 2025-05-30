module ActiveScaffoldExport
  class Engine < ::Rails::Engine
    initializer 'active_scaffold_export.routes' do
      ActiveSupport.on_load :active_scaffold_routing do
        self::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection][:show_export] = :get
        self::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection][:export] = :post
        unless Mime[:xlsx]
          Mime::Type.register 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx
        end
        unless Mime[:csv]
          Mime::Type.register 'text/csv', :csv
        end
      end
    end

    initializer 'active_scaffold_export.extensions' do
      ActiveScaffold::DataStructures::Column.send :include, ActiveScaffoldExport::Column
      if defined? ActiveScaffold::DataStructures::ProxyColumn
        ActiveScaffold::DataStructures::ProxyColumn.send :include, ActiveScaffoldExport::Column
      end
    end
  end
end
