# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/core_ext/module/attribute_accessors'

module ActiveScaffold
  module DataStructures
    class ActionLink
      attr_reader :action, :options

      def initialize(action, **options)
        @action = action
        @options = options
      end
    end

    class Set
      def initialize(*values)
        @values = values
      end

      def to_a
        @values
      end
    end
  end

  module Config
    class Form
      attr_accessor :formats

      def self.crud_type=(_value); end

      def self.columns_accessor(name)
        attr_accessor name
      end

      class UserSettings
        def self.user_attr(*); end
      end

      def initialize(*); end
    end
  end
end

require_relative '../../lib/active_scaffold/config/export'

class ExportConfigTest < Minitest::Test
  def test_defaults_are_copied_to_instance
    config = ActiveScaffold::Config::Export.new(Object.new)

    assert config.show_form
    assert config.allow_full_download
    refute config.force_quotes
    assert config.default_full_download
    assert_equal ',', config.default_delimiter
    refute config.default_skip_header
    assert_equal %i[csv xlsx], config.formats
  end

  def test_form_link_opens_export_options
    config = ActiveScaffold::Config::Export.new(Object.new)

    assert_equal 'show_export', config.link.action
    assert_equal :collection, config.link.options[:type]
  end

  def test_direct_link_skips_form_and_uses_export_action
    config = ActiveScaffold::Config::Export.new(Object.new)
    config.show_form = false

    assert_equal 'export', config.link.action
    assert_equal false, config.link.options[:inline]
  end

  def test_default_deselected_columns_are_wrapped_in_set
    config = ActiveScaffold::Config::Export.new(Object.new)

    config.default_deselected_columns = %i[secret internal]

    assert_equal %i[secret internal], config.default_deselected_columns.to_a
  end

  def test_export_form_is_not_multipart
    config = ActiveScaffold::Config::Export.new(Object.new)

    refute config.multipart?
  end
end
