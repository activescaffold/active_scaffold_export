# frozen_string_literal: true

require 'test_helper'

class TemplatesTest < Minitest::Test
  VIEW_PATH = File.expand_path('../../app/views', __dir__)
  LOOKUP_CONTEXT = ActionView::LookupContext.new([VIEW_PATH])

  Column = Struct.new(:name)
  ExportConfig = Struct.new(
    :allow_full_download,
    :default_full_download,
    :formats,
    :default_file_format,
    :default_deselected_columns,
    :draggable,
    :force_quotes
  )
  Config = Struct.new(:export)
  Record = Struct.new(:name, :status)

  class Columns
    def initialize(columns)
      @columns = columns
    end

    def visible_columns
      @columns
    end
  end

  class ViewContext < ActionView::Base
    attr_accessor :params
    attr_reader :render_calls

    def initialize(lookup_context, assigns, controller)
      super
      @params = {delimiter: ',', skip_header: false}
      @render_calls = []
    end

    def render_root(options)
      @render_root = true
      render(options)
    ensure
      @render_root = false
    end

    def render(options = {}, locals = {}, &)
      if @render_root
        @render_root = false
        super
      else
        render_calls << [options, locals]
        '[rendered]'.html_safe
      end
    end

    def active_scaffold_config
      @active_scaffold_config ||= Config.new(@export_config)
    end

    def export_columns_names(action_columns:)
      raise 'action columns are required' unless action_columns

      Columns.new(@export_columns)
    end

    def format_export_column_header_name(column)
      column.name.to_s.upcase
    end

    def get_export_column_value(record, column, _format)
      [record.public_send(column.name), nil]
    end

    def column_heading_label(column)
      column.name.to_s.capitalize
    end

    def active_scaffold_checkbox_list(*)
      'column-checkboxes'
    end

    def export_options
      [[['delimiter-field', :delimiter]]]
    end

    def form_attribute_html(_column, label, content, *)
      "#{label}:#{content}"
    end

    def as_element(_name, content = nil, **, &block)
      content = capture(&block) if block
      content.to_s
    end

    def as_(key)
      key.to_s
    end

    def element_form_id(action:)
      "records-#{action}"
    end

    def params_for(**options)
      options
    end
  end

  CompiledViewContext = ViewContext.with_empty_template_cache

  def setup
    @columns = [Column.new(:name), Column.new(:status)]
    @export_config = ExportConfig.new(true, true, %i[csv xlsx], 'csv', Set.new, true, false)
    assigns = {
      export_columns: @columns,
      export_config: @export_config,
      records: [Record.new('Task', 'Open')]
    }
    @view = CompiledViewContext.new(LOOKUP_CONTEXT, assigns, nil)
  end

  def test_renders_csv_with_headers_and_records
    output = @view.render_root(
      partial: 'active_scaffold_overrides/export',
      formats: [:csv]
    )

    assert_equal "NAME,STATUS\nTask,Open\n", output
  end

  def test_executes_every_export_form_partial
    partials = {
      export_columns_form: {export_config: @export_config},
      export_download_options: {export_config: @export_config},
      export_form_body: {},
      export_options_form: {},
      show_export: {}
    }

    partials.each do |name, locals|
      output = @view.render_root(partial: "active_scaffold_overrides/#{name}", locals: locals)
      refute_nil output, "expected #{name} to render"
    end
  end

  def test_executes_show_export_page
    output = @view.render_root(template: 'active_scaffold_overrides/show_export')

    assert_includes output, 'show-export'
  end

  def test_single_format_is_submitted_in_hidden_field
    @export_config.formats = [:csv]

    output = @view.render_root(
      partial: 'active_scaffold_overrides/export_download_options',
      locals: {export_config: @export_config}
    )

    assert_includes output, 'name="format"'
    assert_includes output, 'value="csv"'
  end
end
