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
      @formats = [:csv, :xlsx]
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_export', :label => :export, :type => :collection, :security_method => :export_authorized?)

    # configures where the plugin itself is located. there is no instance version of this.
    cattr_accessor :plugin_directory
    @@plugin_directory = File.expand_path(__FILE__).match(%{(^.*)/lib/active_scaffold/config/export.rb})[1]


    # instance-level configuration
    # ----------------------------

    attr_writer :link
    def link
      @link ||= if show_form
        self.class.link.clone
      else
        ActiveScaffold::DataStructures::ActionLink.new('export', :label => :export, :type => :collection, :inline => false, :security_method => :export_authorized?)
      end
    end

    # whether open a form to allow selecting columns and format settings, or export directly with the defined settings in the controller
    cattr_accessor :show_form, instance_accessor: false
    @@show_form = true

    # whether user can ask for full or page export, or default is forced
    cattr_accessor :allow_full_download, instance_accessor: false
    @@allow_full_download = true

    # force_quotes option for CSV library
    cattr_accessor :force_quotes, instance_accessor: false
    @@force_quotes = false

    # default setting for full export or page export, it can be changed in the form if show_form is enabled
    cattr_accessor :default_full_download, instance_accessor: false
    @@default_full_download = true

    # default column separator for CSV, it can be changed in the form if show_form is enabled
    cattr_accessor :default_delimiter, instance_accessor: false
    @@default_delimiter = ','

    # wheter export a header (false) or skip exporting a header (true), it can be changed in the form if show_form is enabled
    cattr_accessor :default_skip_header, instance_accessor: false
    @@default_skip_header = false

    # default file format to export, it can be changed in the form if show_form is enabled
    cattr_accessor :default_file_format, instance_accessor: false
    @@default_file_format = Gem::Specification::find_all_by_name('caxlsx').any? ? 'xlsx' : 'csv'

    # instance-level configuration
    # ----------------------------

    # whether open a form to allow selecting columns and format settings, or export directly with the defined settings in the controller
    attr_accessor :show_form

    # whether user can ask for full or page export, or default is forced
    attr_accessor :allow_full_download

    # force_quotes option for CSV library
    attr_accessor :force_quotes

    # default setting for full export or page export, it can be changed in the form if show_form is enabled
    attr_accessor :default_full_download

    # default column separator for CSV, it can be changed in the form if show_form is enabled
    attr_accessor :default_delimiter

    # wheter export a header (false) or skip exporting a header (true), it can be changed in the form if show_form is enabled
    attr_accessor :default_skip_header

    # default file format to export, it can be changed in the form if show_form is enabled
    attr_accessor :default_file_format

    def default_deselected_columns=(val)
      @default_deselected_columns = ActiveScaffold::DataStructures::Set.new(*val)
    end

    def default_deselected_columns
      self.default_deselected_columns = ActiveScaffold::DataStructures::Set.new if @default_deselected_columns.nil?
      @default_deselected_columns
    end

    columns_accessor :columns

    def multipart?
      false
    end
  end
end
