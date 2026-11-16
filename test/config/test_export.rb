# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/module/attribute_accessors'

require_relative '../../lib/active_scaffold/config/export'

class ExportConfigTest < Minitest::Test
  class Core
    def model_id
      :record
    end
  end

  def build_config
    ActiveScaffold::Config::Export.new(Core.new)
  end

  def test_defaults_are_copied_to_instance
    config = build_config

    assert config.show_form
    assert config.allow_full_download
    refute config.force_quotes
    assert config.default_full_download
    assert_equal ',', config.default_delimiter
    refute config.default_skip_header
    assert_equal %i[csv xlsx], config.formats
  end

  def test_form_link_opens_export_options
    config = build_config

    assert_equal 'show_export', config.link.action
    assert_equal :collection, config.link.type
  end

  def test_direct_link_skips_form_and_uses_export_action
    config = build_config
    config.show_form = false

    assert_equal 'export', config.link.action
    refute config.link.inline?
  end

  def test_default_deselected_columns_are_wrapped_in_set
    config = build_config

    config.default_deselected_columns = %i[secret internal]

    assert_equal %i[secret internal], config.default_deselected_columns.to_a
  end

  def test_export_form_is_not_multipart
    config = build_config

    refute config.multipart?
  end

  def test_user_deselected_columns_inherit_and_override_configuration
    export_config = build_config
    export_config.default_deselected_columns = [:secret]
    settings = ActiveScaffold::Config::Export::UserSettings.new(export_config, {}, {})

    assert_same export_config.default_deselected_columns, settings.default_deselected_columns

    settings.default_deselected_columns = [:internal]
    assert_equal [:internal], settings.default_deselected_columns.to_a

    empty_config = build_config
    empty_config.freeze
    empty_settings = ActiveScaffold::Config::Export::UserSettings.new(empty_config, {}, {})
    assert_empty empty_settings.default_deselected_columns
  end
end
