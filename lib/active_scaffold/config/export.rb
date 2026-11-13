# frozen_string_literal: true

module ActiveScaffold::Config
  class Export < ActiveScaffold::Config::Form
    self.crud_type = :read

    def initialize(core_config)
      super
      @core = core_config
      self.show_form = self.class.show_form
      self.allow_full_download = self.class.allow_full_download
      self.force_quotes = self.class.force_quotes
      self.default_full_download = self.class.default_full_download
      self.default_delimiter = self.class.default_delimiter
      self.default_skip_header = self.class.default_skip_header
      self.default_file_format = self.class.default_file_format
      self.draggable = self.class.draggable
      @formats = %i[csv xlsx]
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_accessor :link,
                   instance_accessor: false,
                   default: ActiveScaffold::DataStructures::ActionLink.new(
                     'show_export', label: :export, type: :collection, security_method: :export_authorized?
                   )

    # configures where the plugin itself is located. there is no instance version of this.
    cattr_accessor :plugin_directory,
                   instance_accessor: false,
                   default: File.expand_path(__FILE__).match(%r{(^.*)/lib/active_scaffold/config/export.rb})[1]

    # instance-level configuration
    # ----------------------------

    attr_writer :link

    def link
      @link ||=
        if show_form
          self.class.link.clone
        else
          ActiveScaffold::DataStructures::ActionLink.new(
            'export', label: :export, type: :collection, inline: false, security_method: :export_authorized?
          )
        end
    end

    # whether open a form to allow selecting columns and format settings,
    # or export directly with the defined settings in the controller
    cattr_accessor :show_form, instance_accessor: false, default: true

    # whether user can ask for full or page export, or default is forced
    cattr_accessor :allow_full_download, instance_accessor: false, default: true

    # force_quotes option for CSV library
    cattr_accessor :force_quotes, instance_accessor: false, default: false

    # default setting for full export or page export, it can be changed in the form if show_form is enabled
    cattr_accessor :default_full_download, instance_accessor: false, default: true

    # default column separator for CSV, it can be changed in the form if show_form is enabled
    cattr_accessor :default_delimiter, instance_accessor: false, default: ','

    # wheter export a header (false) or skip exporting a header (true),
    # it can be changed in the form if show_form is enabled
    cattr_accessor :default_skip_header, instance_accessor: false, default: false

    # default file format to export, it can be changed in the form if show_form is enabled
    cattr_accessor :default_file_format,
                   instance_accessor: false,
                   default: Gem::Specification.find_all_by_name('caxlsx').any? ? 'xlsx' : 'csv'

    # whether selected export columns can be reordered with drag and drop
    cattr_accessor :draggable, instance_accessor: false, default: false

    # instance-level configuration
    # ----------------------------

    # whether open a form to allow selecting columns and format settings,
    # or export directly with the defined settings in the controller
    attr_accessor :show_form

    # whether user can ask for full or page export, or default is forced
    attr_accessor :allow_full_download

    # force_quotes option for CSV library
    attr_accessor :force_quotes

    # default setting for full export or page export, it can be changed in the form if show_form is enabled
    attr_accessor :default_full_download

    # default column separator for CSV, it can be changed in the form if show_form is enabled
    attr_accessor :default_delimiter

    # wheter export a header (false) or skip exporting a header (true),
    # it can be changed in the form if show_form is enabled
    attr_accessor :default_skip_header

    # default file format to export, it can be changed in the form if show_form is enabled
    attr_accessor :default_file_format

    # whether selected export columns can be reordered with drag and drop
    attr_accessor :draggable

    def default_deselected_columns=(val)
      @default_deselected_columns = ActiveScaffold::DataStructures::Set.new(*val)
    end

    def default_deselected_columns
      @default_deselected_columns ||= ActiveScaffold::DataStructures::Set.new unless frozen?
      @default_deselected_columns
    end

    columns_accessor :columns

    def multipart?
      false
    end

    UserSettings.class_eval do
      user_attr :show_form, :allow_full_download, :force_quotes, :default_file_format,
                :default_delimiter, :default_skip_header, :default_file_format

      def default_deselected_columns=(val)
        @default_deselected_columns = ActiveScaffold::DataStructures::Set.new(*val)
      end

      def default_deselected_columns
        if @default_deselected_columns.nil? && @conf.default_deselected_columns
          return @conf.default_deselected_columns
        end

        @default_deselected_columns ||= ActiveScaffold::DataStructures::Set.new
      end
    end
  end
end
