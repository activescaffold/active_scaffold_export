# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/filters'

module ActiveScaffold
  module Actions
  end
end

module Axlsx
  WORKSHEET_NAME_FORBIDDEN_CHARS = %w[* / : ? [ \\ ]].freeze
  WORKSHEET_MAX_NAME_LENGTH = 31
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

    attr_accessor :page, :raise_search_error
    attr_reader :active_scaffold_config, :params

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

    def set_page(items:, pages: [])
      @page = Page.new(items, Pager.new(pages.map { |page_items| Page.new(page_items, nil) }))
      instance_variable_set(:@page, @page)
    end

    public :export_columns, :export_file_name, :find_items_for_export, :find_options_for_export,
           :requested_export_columns, :selected_export_columns, :worksheet_name
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
end
