# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/filters'
require 'stringio'

module ActiveScaffold
  unless const_defined?(:ActionNotAllowed)
    class ActionNotAllowed < StandardError
    end
  end

  module Actions
  end
end

module Axlsx
  WORKSHEET_NAME_FORBIDDEN_CHARS = %w[* / : ? [ \\ ]].freeze
  WORKSHEET_MAX_NAME_LENGTH = 31

  class Styles
    attr_reader :added

    def initialize
      @added = []
    end

    def add_style(style)
      added << style
      "style-#{added.length}"
    end
  end

  class Sheet
    attr_reader :rows

    def initialize
      @rows = []
    end

    def add_row(values, **options)
      rows << [values, options]
    end
  end

  class Workbook
    attr_reader :styles, :sheet, :worksheet_name

    def initialize
      @styles = Styles.new
    end

    def add_worksheet(name:)
      @worksheet_name = name
      @sheet = Sheet.new
      yield sheet
    end
  end

  class Package
    class << self
      attr_accessor :last
    end

    attr_reader :workbook

    def initialize
      @workbook = Workbook.new
      self.class.last = self
    end

    def to_stream
      StringIO.new('xlsx-data')
    end
  end
end

module Mime
  def self.[](format)
    "mime/#{format}"
  end
end

require_relative '../../lib/active_scaffold/actions/export'

class ExportActionsTest < Minitest::Test
  Column = Struct.new(:name, :export_options)
  ExportConfig = Struct.new(
    :columns,
    :formats,
    :default_file_format,
    :default_full_download,
    :default_delimiter,
    :default_skip_header
  )
  ListUser = Struct.new(:sorting, :per_page, :page)
  ListConfig = Struct.new(:sorting, :pagination, :user)
  Config = Struct.new(:export, :list, :columns, :model, :label)
  Pager = Struct.new(:pages) do
    def each(&)
      pages.each(&)
    end
  end
  Page = Struct.new(:items, :pager)
  Response = Struct.new(:headers)

  class Responder
    def html; end

    def js
      yield
    end
  end

  class ViewContext
    def export_column_header_style(column, _format)
      column.name == 'name' ? {width: 20, b: true} : nil
    end

    def format_export_column_header_name(column)
      column.name.upcase
    end

    def get_export_column_value(record, column, _format)
      [record.fetch(column.name.to_sym), column.name == 'status' ? {italic: true} : nil]
    end
  end

  class Model
    class << self
      attr_accessor :denied_columns

      def authorized_for?(column:, **)
        Array(denied_columns).none?(column)
      end
    end
  end

  class Controller
    def self.before_action(*); end

    def self.helper_method(*); end

    include ActiveScaffold::Actions::Export

    attr_accessor :page, :raise_search_error, :response_body, :view_context, :authorized
    attr_reader :active_scaffold_config, :params, :response, :rendered, :responded_action,
                :includes_action, :find_page_options

    def initialize
      name = Column.new('name')
      status = Column.new('status')
      created_at = Column.new('created_at')
      export = ExportConfig.new(
        %i[name status],
        %i[csv xlsx],
        'csv',
        true,
        ',',
        false
      )
      list_user = ListUser.new(nil, 25, 3)
      list = ListConfig.new([[created_at, :desc]], true, list_user)
      @active_scaffold_config = Config.new(
        export,
        list,
        {'name' => name, 'status' => status, 'created_at' => created_at},
        Model,
        'Tasks / 2026: overview?'
      )
      @params = {}
      @page = Page.new([], Pager.new([]))
      @raise_search_error = false
      @response = Response.new({})
      @view_context = ViewContext.new
      @authorized = true
    end

    def grouped_search?
      false
    end

    def do_search
      raise 'invalid search' if raise_search_error
    end

    def controller_name
      +'tasks'
    end

    def respond_to
      yield Responder.new
    end

    def render(**options)
      @rendered = options
    end

    def render_to_string(**)
      'csv-data'
    end

    def set_includes_for_columns(action) # rubocop:disable Naming/AccessorMethodName -- mirrors the controller API
      @includes_action = action
      export_columns
    end

    def find_page(options)
      @find_page_options = options
      @page
    end

    def respond_to_action(action)
      @responded_action = action
    end

    def authorized_for?(action:)
      authorized && action == :read
    end

    def set_page(items:, pages: [])
      @page = Page.new(items, Pager.new(pages.map { |page_items| Page.new(page_items, nil) }))
      instance_variable_set(:@page, @page)
    end

    public :add_xlsx_header, :add_xlsx_record, :export_authorized?, :export_authorized_filter,
           :export_columns, :export_file_name, :export_respond_to_csv, :export_respond_to_xlsx,
           :find_items_for_export, :find_options_for_export, :populate_xlsx_sheet,
           :requested_export_columns, :selected_export_columns, :show_export_authorized?,
           :show_export_authorized_filter, :worksheet_name, :xlsx_column_widths
  end

  class ControllerWithoutSearch < Controller
    undef_method :do_search
  end

  def setup
    Model.denied_columns = []
  end

  def test_requested_columns_accept_checkbox_hash_and_discard_unchecked_values
    controller = Controller.new
    controller.params[:export_columns] = {'name' => '1', 'status' => '', 'unknown' => nil}

    assert_equal ['name'], controller.requested_export_columns
  end

  def test_requested_columns_accept_array_and_discard_blank_values
    controller = Controller.new
    controller.params[:export_columns] = [:name, '', nil, :status]

    assert_equal %w[name status], controller.requested_export_columns
  end

  def test_selected_columns_are_unique_available_and_authorized
    controller = Controller.new
    controller.params[:export_columns] = %w[name name status missing]
    Model.denied_columns = [:status]

    assert_equal ['name'], controller.selected_export_columns
  end

  def test_export_columns_append_sorting_columns_needed_by_query
    controller = Controller.new
    controller.params[:export_columns] = ['name']

    assert_equal %w[name created_at], controller.export_columns.map(&:name)
  end

  def test_full_download_uses_first_page_and_large_batch
    controller = Controller.new
    controller.params[:full_download] = 'true'

    assert_equal(
      {sorting: controller.active_scaffold_config.list.sorting, pagination: true, per_page: 3000, page: 1},
      controller.find_options_for_export
    )
  end

  def test_page_download_uses_current_list_pagination
    controller = Controller.new

    assert_equal(
      {
        sorting: controller.active_scaffold_config.list.sorting,
        pagination: true,
        per_page: 25,
        page: 3
      },
      controller.find_options_for_export
    )
  end

  def test_search_errors_are_not_suppressed
    controller = Controller.new
    controller.raise_search_error = true

    error = assert_raises(RuntimeError) { controller.find_options_for_export }

    assert_equal 'invalid search', error.message
  end

  def test_find_options_work_without_search_action
    controller = ControllerWithoutSearch.new

    assert_equal 25, controller.find_options_for_export[:per_page]
  end

  def test_full_download_yields_every_pager_batch
    controller = Controller.new
    controller.params[:full_download] = 'true'
    controller.set_page(items: [:ignored], pages: [[:first], %i[second third]])
    yielded = []

    controller.find_items_for_export { |items| yielded << items }

    assert_equal [[:first], %i[second third]], yielded
  end

  def test_page_download_yields_only_current_page
    controller = Controller.new
    controller.set_page(items: %i[first second], pages: [[:ignored]])
    yielded = []

    controller.find_items_for_export { |items| yielded << items }

    assert_equal [%i[first second]], yielded
  end

  def test_file_name_uses_requested_supported_format
    controller = Controller.new
    controller.params[:format] = 'xlsx'

    assert_equal 'tasks.xlsx', controller.export_file_name
  end

  def test_file_name_falls_back_to_default_for_unknown_format
    controller = Controller.new
    controller.params[:format] = 'pdf'

    assert_equal 'tasks.csv', controller.export_file_name
  end

  def test_worksheet_name_replaces_forbidden_characters_and_obeys_limit
    controller = Controller.new

    name = controller.worksheet_name

    assert_equal 'Tasks - 2026- overview-', name
    assert_operator name.length, :<=, 31
  end

  def test_show_export_renders_the_js_partial
    controller = Controller.new

    controller.show_export

    assert_same controller.active_scaffold_config.export, controller.instance_variable_get(:@export_config)
    assert_equal({partial: 'show_export'}, controller.rendered)
  end

  def test_export_applies_defaults_finds_page_and_sets_download_headers
    controller = Controller.new

    controller.export

    assert_equal %w[name status], controller.params[:export_columns]
    assert_equal 'true', controller.params[:full_download]
    assert_equal ',', controller.params[:delimiter]
    assert_equal 'false', controller.params[:skip_header]
    assert_equal :export, controller.includes_action
    assert_equal 3000, controller.find_page_options[:per_page]
    assert_equal 'attachment; filename=tasks.csv', controller.response.headers['content-disposition']
    assert_equal :export, controller.responded_action
  end

  def test_csv_response_streams_each_page_and_skips_later_headers
    controller = Controller.new
    controller.params[:full_download] = 'true'
    controller.set_page(items: [], pages: [[:first], [:second]])

    controller.export_respond_to_csv

    assert_equal 'mime/csv', controller.response.headers['content-type']
    assert_equal '0', controller.response.headers['last-modified']
    assert_equal %w[csv-data csv-data], controller.response_body.to_a
    assert_equal 'true', controller.params[:skip_header]
  end

  def test_xlsx_response_populates_and_streams_workbook
    controller = Controller.new
    controller.params[:export_columns] = %w[name status]
    controller.instance_variable_set(:@export_columns, controller.export_columns)
    controller.set_page(items: [{name: 'Task', status: 'Open', created_at: '2026-11-16'}])

    controller.export_respond_to_xlsx

    package = Axlsx::Package.last
    assert_equal 'mime/xlsx', controller.response.headers['content-type']
    assert_equal 'Tasks - 2026- overview-', package.workbook.worksheet_name
    assert_equal %w[NAME STATUS CREATED_AT], package.workbook.sheet.rows.first.first
    assert_equal 'xlsx-data', controller.response_body.to_a.join
  end

  def test_xlsx_widths_prefer_header_then_column_options_then_auto
    controller = Controller.new
    controller.params[:export_columns] = %w[name status]
    columns = controller.export_columns
    columns[1].export_options = {xlsx: {width: 10}}
    controller.instance_variable_set(:@export_columns, columns)

    assert_equal [20, 10, :auto], controller.xlsx_column_widths([{width: 20}, nil, nil])
  end

  def test_authorization_filters_raise_when_read_is_denied
    controller = Controller.new

    assert controller.export_authorized?
    assert controller.show_export_authorized?
    controller.authorized = false

    assert_raises(ActiveScaffold::ActionNotAllowed) { controller.export_authorized_filter }
    assert_raises(ActiveScaffold::ActionNotAllowed) { controller.show_export_authorized_filter }
  end
end
