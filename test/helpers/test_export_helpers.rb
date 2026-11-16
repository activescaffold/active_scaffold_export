# frozen_string_literal: true

require 'date'
require 'test_helper'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/deep_dup'

require_relative '../../lib/active_scaffold/helpers/export_helpers'

class ExportHelpersTest < Minitest::Test
  Association = Struct.new(:collection?)
  Column = Struct.new(:name, :association, :list_ui, :list_ui_options, :options, :export_options)
  ListConfig = Struct.new(:empty_field_text)
  ExportConfig = Struct.new(:default_skip_header, :default_delimiter)
  Config = Struct.new(:list, :export)

  class Record
    delegate :[], to: :@attributes

    def initialize(attributes, denied: [])
      @attributes = attributes
      @denied = denied
    end

    def authorized_for?(column:, **)
      @denied.none?(column)
    end

    def method_missing(name, *)
      return @attributes[name] if @attributes.key?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      @attributes.key?(name) || super
    end
  end

  Label = Struct.new(:to_label)

  class Helper
    include ActiveScaffold::Helpers::ExportHelpers

    attr_accessor :column_override, :grouped, :search_group_column
    attr_reader :localized

    def active_scaffold_config
      Config.new(ListConfig.new('(empty)'), ExportConfig.new(true, ';'))
    end

    def grouped_search?
      grouped || false
    end

    def override_helper(*)
      column_override
    end

    def custom_export_column(record, format)
      ["custom-#{record.name}-#{format}", nil]
    end

    def search_group_function
      :count
    end

    def format_grouped_search_column(value, options)
      "grouped-#{value}-#{options[:suffix]}"
    end

    def active_scaffold_export_badge(record, column, format, ui_options:)
      ["#{record.send(column.name)}-#{format}-#{ui_options[:badge]}", nil]
    end

    def column_heading_label(column)
      "Heading #{column.name}"
    end

    def check_box_tag(name, value, checked)
      "checkbox:#{name}:#{value}:#{checked}"
    end

    def text_field_tag(name, value, options)
      "text:#{name}:#{value}:#{options[:size]}"
    end

    def column_empty?(value)
      value.nil? || value == ''
    end

    def as_(key)
      "translated-#{key}"
    end

    def l(value, format:)
      @localized = [value, format]
      'localized-date'
    end

    def format_value(value)
      value
    end
  end

  def setup
    @helper = Helper.new
  end

  def column(name, association: nil, export_options: nil)
    Column.new(name, association, nil, nil, {}, export_options)
  end

  def test_unauthorized_column_returns_nil
    record = Record.new({name: 'Secret'}, denied: [:name])

    assert_nil @helper.get_export_column_value(record, column(:name), :csv)
  end

  def test_plain_value_is_formatted_for_csv
    record = Record.new({name: 'Task'})

    assert_equal ['Task', nil], @helper.get_export_column_value(record, column(:name), :csv)
  end

  def test_empty_csv_value_uses_list_placeholder
    assert_equal '(empty)', @helper.format_value_for_csv(nil)
  end

  def test_boolean_csv_value_is_translated
    assert_equal 'translated-true', @helper.format_value_for_csv(true)
    assert_equal 'translated-false', @helper.format_value_for_csv(false)
  end

  def test_date_csv_value_is_localized
    date = Date.new(2026, 11, 13)

    assert_equal 'localized-date', @helper.format_value_for_csv(date)
    assert_equal [date, :default], @helper.localized
  end

  def test_singular_association_uses_label
    record = Record.new({owner: Label.new('Sergio')})

    assert_equal 'Sergio', @helper.format_export_record_value(record, column(:owner, association: Association.new(false)), :csv)
  end

  def test_plural_association_limits_output_to_first_three_labels
    labels = %w[One Two Three Four Five].map { |label| Label.new(label) }
    record = Record.new({tags: labels})

    assert_equal 'One,Two,Three, ', @helper.format_export_record_value(record, column(:tags, association: Association.new(true)), :csv)
  end

  def test_frozen_xlsx_style_is_duplicated_before_use
    alignment = {horizontal: :center}.freeze
    style = {alignment: alignment}.freeze
    export_column = column(:name, export_options: {xlsx: style})

    result = @helper.export_column_style(export_column, :xlsx)

    assert_equal style, result
    refute_same style, result
    refute_same style[:alignment], result[:alignment]
  end

  def test_csv_style_is_returned_without_duplication
    style = {force_quotes: true}.freeze
    export_column = column(:name, export_options: {csv: style})

    assert_same style, @helper.export_column_style(export_column, :csv)
  end

  def test_header_style_is_only_added_for_xlsx
    assert_equal({sz: 11, b: true, bg_color: '69B5EF', fg_color: 'FF', alignment: {horizontal: :center}},
                 @helper.export_column_header_style(column(:name), :xlsx))
    assert_nil @helper.export_column_header_style(column(:name), :csv)
  end

  def test_list_ui_override_formats_the_export_value
    export_column = column(:name)
    export_column.list_ui = :badge
    export_column.list_ui_options = {badge: 'urgent'}

    value = @helper.export_column_value(Record.new({name: 'Task'}), export_column, :csv)

    assert_equal ['Task-csv-urgent', nil], value
  end

  def test_column_override_takes_precedence
    @helper.column_override = :custom_export_column
    export_column = column(:name)

    assert_equal ['custom-Task-csv', nil],
                 @helper.export_column_value(Record.new({name: 'Task'}), export_column, :csv)
  end

  def test_grouped_search_column_uses_group_formatter
    @helper.grouped = true
    export_column = column(:count)
    export_column.options = {suffix: 'tasks'}
    @helper.search_group_column = export_column

    assert_equal ['grouped-3-tasks', nil],
                 @helper.export_column_value(Record.new({count: 3}), export_column, :csv)
  end

  def test_format_export_column_preserves_value_without_formatter
    value = Object.new

    assert_same value, @helper.format_export_column(value, :unknown)
  end

  def test_header_name_uses_column_heading_label
    assert_equal 'Heading name', @helper.format_export_column_header_name(column(:name))
  end

  def test_export_options_include_header_and_delimiter_controls
    assert_equal [
      [
        ['checkbox:skip_header:1:true', :omit_header],
        ['text:delimiter:;:1', :delimiter]
      ]
    ], @helper.export_options
  end
end
