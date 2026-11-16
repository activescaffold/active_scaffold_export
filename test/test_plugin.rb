# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold/extensions/routing_mapper'

class PluginTest < Minitest::Test
  def test_entry_point_registers_stylesheet_ui_elements_and_root
    assert_includes ActiveScaffold.stylesheets, 'active_scaffold_export'
    assert_equal({tag: :div, attributes: {class: 'export-option'}}, ActiveScaffold.ui_elements[:export_option])
    assert_equal({tag: :div, attributes: {class: 'export-option-row'}},
                 ActiveScaffold.ui_elements[:export_option_row])
    assert_equal File.expand_path('..', __dir__), File.expand_path(ActiveScaffoldExport.root)
  end

  def test_extensions_load_export_action_configuration_and_helpers
    expected_sources = {
      ActiveScaffold::Actions::Export.instance_method(:show_export) =>
        'lib/active_scaffold/actions/export.rb',
      ActiveScaffold::Config::Export.instance_method(:multipart?) =>
        'lib/active_scaffold/config/export.rb',
      ActiveScaffold::Helpers::ExportHelpers.instance_method(:export_options) =>
        'lib/active_scaffold/helpers/export_helpers.rb'
    }

    expected_sources.each do |method, relative_path|
      assert_equal File.expand_path("../#{relative_path}", __dir__), method.source_location.first
    end
  end

  def test_engine_defines_named_initializers
    assert_equal(
      %w[
        active_scaffold_export.routes
        active_scaffold_export.extensions
        active_scaffold_export.action_view
      ],
      ActiveScaffoldExport::Engine.initializers.map(&:name)
    )
  end

  def test_routes_initializer_registers_routes_and_mime_types
    run_initializer('active_scaffold_export.routes')

    routes = ActiveScaffold::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING.fetch(:collection)
    assert_equal :get, routes[:show_export]
    assert_equal :post, routes[:export]
    assert_equal 'text/csv', Mime[:csv].to_s
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', Mime[:xlsx].to_s
  end

  def test_extensions_initializer_adds_export_options_to_columns
    run_initializer('active_scaffold_export.extensions')

    column = ActiveScaffold::DataStructures::Column.allocate
    column.export_options = {xlsx: {width: 20}}
    assert_equal({xlsx: {width: 20}}, column.export_options)

    if defined?(ActiveScaffold::DataStructures::ProxyColumn)
      assert_includes ActiveScaffold::DataStructures::ProxyColumn.ancestors, ActiveScaffoldExport::Column
    end
  end

  def test_action_view_initializer_installs_export_helpers
    run_initializer('active_scaffold_export.action_view')

    assert_includes ActionView::Base.ancestors, ActiveScaffold::Helpers::ExportHelpers
  end

  private

  def run_initializer(name)
    ActiveScaffoldExport::Engine.initializers.find { |initializer| initializer.name == name }.run
  end
end
