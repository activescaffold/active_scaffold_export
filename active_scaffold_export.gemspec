$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'active_scaffold_export/version'

Gem::Specification.new do |s|
  s.name = "active_scaffold_export"
  s.version = ActiveScaffoldExport::Version::STRING

  s.authors = ["Volker Hochstein", "Sergio Cambra", "Hernan Astudillo"]
  s.description = "Exporting Records with ActiveScaffold"
  s.email = "activescaffold@googlegroups.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = Dir["{app,lib}/**/*"] + %w[LICENSE.txt README.md]
  s.homepage = "http://github.com/active_scaffold/active_scaffold_export"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.summary = "Ability to export records to CSV/XLSX with ActiveScaffold"
  s.required_ruby_version = '>= 2.5'
  s.add_runtime_dependency 'active_scaffold', '>= 4.0.0.rc1'
end
