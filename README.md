# Active Scaffold Export
An [active scaffold](https://github.com/activescaffold/active_scaffold) addon to let it export data in CSV or XLSX format

### How to?
Easy. First get [active scaffold](https://github.com/activescaffold/active_scaffold) if you haven't yet. 
Then, add this to your Gemfile:
```
gem 'active_scaffold_export'
```

If you want xlsx format, add:
```
gem 'caxlsx_rails'
```

If that gem is present, XLSX will be used by default. 
You can change this by adding to active scaffold config:
```
conf.export.default_file_format = 'csv' # or 'xlsx' 
```

Read important notes at the bottom about xlsx.

Remember to bundle install.
Add to application.css:
```
 *= require active_scaffold_export
```

Now let's add it to controller, inside active_scaffold config block:
```ruby
conf.actions.add :export
# you can filter or sort columns if you want
conf.export.columns = %w(name last_name phone address) 
# you can define a default values for the exporting form
conf.export.default_deselected_columns = %w(phone address)
conf.export.default_delimiter = ";"
conf.export.force_quotes = "true"
```
And enjoy happy exporting :)

### Configuring

There are other options for the action export, explained in the wiki [Export Configuration](https://github.com/activescaffold/active_scaffold_export/wiki/Export-Configuration),
and it's possible to define [helper overrides](https://github.com/activescaffold/active_scaffold_export/wiki/Helper-Overrides) to change the exported value.

### Security
It's controlled the same way as Active Scaffold. The extra actions added are:
* **:show_export** for the options form
* **:export** for retrieving the data
Tested with AS internal security and [Cancan](https://github.com/ryanb/cancan)

### Translations 
Go in the same active scaffold scope:
```yaml
active_scaffold:
    columns_for_export: Columnas para exportar
    export_options: Opciones de exportación
    this_page: esta página
    all_pages: todas las páginas 
```

### XLSX support 
This support depends on caxlsx_rails and caxlsx of course, and supports changing the style of cells and headers, as explained 
in the wiki [Cell Format Options](https://github.com/activescaffold/active_scaffold_export/wiki/Cell-Format-Options). Also,
the [helper overrides](https://github.com/activescaffold/active_scaffold_export/wiki/Helper-Overrides#column-helper) may return
a hash with format options besides the value.

NOTE: There's NO streaming support for xlsx format. Only CSV. So if your data is huge, set default_file_format to 'csv' instead.
Streaming in xlsx will never be supported since the entire file needs to be serialized and zipped to be a valid OOXML file. 
So, rather than streaming, background jobs will be the most likely future approach.  
[Read axlsx issue about this](https://github.com/randym/axlsx/issues/169#issuecomment-13252750)

The sheet name is generated from conf.label, replacing forbidden chars with '-' and truncated to 31. The generated name can be changed defining workseet_name method in the controller, and calling super with options for truncate String method, and :replace option to use other character, e.g.

```ruby
def worksheet_name(options = {})
  super replace: '_', omission: ''
end
```

### Grouped search

Export supports grouped search from field_search action. When grouped search is used, instead of exporting the normal columns, only the listed columns will be exported, the ones in `conf.list.columns` with calculation, or the ones in `conf.field_search.grouped_columns`. In this case, the normal helper overrides won't be used, and will use `grouped_export_column` suffix instead.

## Contact

For contact, help, support, comments, please use Active Scaffold official mailing list  activescaffold@googlegroups.com

