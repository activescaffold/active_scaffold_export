# Need to open the AS module carefully due to Rails 2.3 lazy loading
ActiveScaffold::Config::Core.class_eval do
  # For some note obvious reasons, the class variables need to be defined
  # *before* the cattr !!
  self.send :class_variable_set, :@@export_show_form, true
  self.send :class_variable_set, :@@export_allow_full_download, true
  self.send :class_variable_set, :@@export_default_full_download, true
  self.send :class_variable_set, :@@export_force_quotes, false
  self.send :class_variable_set, :@@export_default_skip_header, false
  self.send :class_variable_set, :@@export_default_delimiter, ','
  self.send :class_variable_set, :@@export_default_file_format, Gem::Specification::find_all_by_name('axlsx_rails').any? ? 'xlsx' : 'csv'
  
  cattr_accessor :export_show_form, :export_allow_full_download,
      :export_force_quotes, :export_default_full_download,
      :export_default_delimiter, :export_default_skip_header, 
      :export_default_file_format, :export_xlsx_avaliable
end
