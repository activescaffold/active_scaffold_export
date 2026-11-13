# frozen_string_literal: true

module ActiveScaffold::Actions
  module Export
    def self.included(base)
      base.before_action :export_authorized_filter, only: [:export]
      base.before_action :show_export_authorized_filter, only: [:show_export]
      base.helper_method :export_columns_names
    end

    # display the customization form or skip directly to export
    def show_export
      @export_config = active_scaffold_config.export
      respond_to do |wants|
        wants.html
        wants.js do
          render partial: 'show_export'
        end
      end
    end

    # if invoked directly, will use default configuration
    def export
      export_config = active_scaffold_config.export
      if params[:export_columns].nil?
        options = {
          export_columns: export_columns_names.map(&:to_s),
          full_download: export_config.default_full_download.to_s,
          delimiter: export_config.default_delimiter,
          skip_header: export_config.default_skip_header.to_s
        }
        params.merge!(options)
      end

      set_includes_for_columns(:export) # will call export_columns which will set @export_columns
      @export_config = export_config
      # Make sure active_scaffold's find_page is dealing with the same list of
      # columns. Prevents an invalid SQL query when exporting after filtering
      # with field_search against a relation column, and that relation column is
      # not included in the set of export columns.
      @list_columns = @export_columns
      @page = find_page(find_options_for_export)

      response.headers['content-disposition'] = "attachment; filename=#{export_file_name}"
      respond_to_action(:export)
    end

    protected

    def export_respond_to_csv
      response.headers['content-type'] = Mime[:csv]
      response.headers['last-modified'] = '0'
      # start streaming output
      self.response_body = Enumerator.new do |y|
        find_items_for_export do |records|
          @records = records
          str = render_to_string partial: 'export', layout: false, formats: [:csv]
          y << str
          params[:skip_header] = 'true' # skip header on the next run
        end
      end
    end

    def export_respond_to_xlsx
      response.headers['content-type'] = Mime[:xlsx]
      response.headers['last-modified'] = '0'
      pkg = Axlsx::Package.new
      pkg.workbook.add_worksheet(name: worksheet_name) do |sheet|
        populate_xlsx_sheet(pkg, sheet)
      end
      customize_xlsx(pkg)
      # Rows added after creating the stream are not included due to an Axlsx limitation.
      stream = pkg.to_stream
      self.response_body = Enumerator.new do |y|
        y << stream.read
      end
    end

    def populate_xlsx_sheet(package, sheet)
      header_styles = @export_columns.map do |column|
        view_context.export_column_header_style(column, :xlsx)
      end
      widths = xlsx_column_widths(header_styles)
      add_xlsx_header(package, sheet, header_styles, widths) unless params[:skip_header]

      find_items_for_export do |records|
        records.each { |record| add_xlsx_record(package, sheet, record, widths) }
      end
    end

    def xlsx_column_widths(header_styles)
      @export_columns.map.with_index do |column, index|
        header_styles.dig(index, :width) || column.export_options&.dig(:xlsx, :width) || :auto
      end
    end

    def add_xlsx_header(package, sheet, header_styles, widths)
      styles = header_styles.map { |style| package.workbook.styles.add_style(style) if style }
      headers = @export_columns.map { |column| view_context.format_export_column_header_name(column) }
      sheet.add_row(headers, style: styles, widths: widths)
    end

    def add_xlsx_record(package, sheet, record, widths)
      cells = @export_columns.map do |column|
        data, style = view_context.get_export_column_value(record, column, :xlsx)
        style = package.workbook.styles.add_style(style) if style
        [data, style]
      end
      sheet.add_row(cells.map(&:first), style: cells.map(&:last), widths: widths)
    end

    def worksheet_name(options = {})
      active_scaffold_config.label
        .gsub(/[#{Regexp.quote Axlsx::WORKSHEET_NAME_FORBIDDEN_CHARS.join}]/, options[:replace] || '-')
        .truncate(Axlsx::WORKSHEET_MAX_NAME_LENGTH, options)
    end

    def customize_xlsx(package); end

    def export_columns
      return @export_columns if defined? @export_columns

      selected_columns = selected_export_columns
      sorting = active_scaffold_config.list.user.sorting || active_scaffold_config.list.sorting
      sorting_columns = sorting.reject { |column, _| selected_columns.include?(column.name) }.map(&:first)
      @export_columns = selected_columns.map { |column| active_scaffold_config.columns[column] }
      @export_columns.concat(sorting_columns)
    end

    def selected_export_columns
      available_columns = export_columns_names.map(&:to_s)
      requested_export_columns.uniq.select do |column|
        available_columns.include?(column) &&
          active_scaffold_config.model.authorized_for?(crud_type: :read, column: column.to_sym)
      end
    end

    def requested_export_columns
      if params[:export_columns].respond_to?(:each_pair)
        params[:export_columns].each_pair.filter_map do |name, selected|
          name.to_s if selected.present?
        end
      else
        Array(params[:export_columns]).compact_blank.map(&:to_s)
      end
    end

    def export_columns_names(action_columns: false)
      if grouped_search?
        list_columns_names.then do |cols|
          action_columns ? active_scaffold_config.build_action_columns(:export, cols) : cols
        end
      else
        active_scaffold_config.export.columns
      end
    end

    def find_options_for_export
      find_options = {sorting: active_scaffold_config.list.sorting, pagination: true}
      do_search if respond_to? :do_search, true

      if params[:full_download] == 'true'
        find_options.merge!(per_page: 3000, page: 1)
      else
        find_options.merge!(
          pagination: active_scaffold_config.list.pagination,
          per_page: active_scaffold_config.list.user.per_page,
          page: active_scaffold_config.list.user.page
        )
      end
      find_options
    end

    # The actual algorithm to do the export
    def find_items_for_export(&)
      if params[:full_download] == 'true'
        @page.pager.each do |page|
          yield page.items
        end
      else
        yield @page.items
      end
    end

    # The default name of the downloaded file.
    # You may override the method to specify your own file name generation.
    def export_file_name
      filename = controller_name.dup

      filename <<
        if params[:format] && active_scaffold_config.export.formats.map(&:to_s).include?(params[:format])
          ".#{params[:format]}"
        else
          ".#{active_scaffold_config.export.default_file_format}"
        end

      filename
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def export_authorized?
      authorized_for?(action: :read)
    end

    def export_authorized_filter
      raise ActiveScaffold::ActionNotAllowed unless export_authorized?
    end

    def show_export_authorized?
      export_authorized?
    end

    def show_export_authorized_filter
      raise ActiveScaffold::ActionNotAllowed unless show_export_authorized?
    end

    def export_formats
      active_scaffold_config.export.formats
    end
  end
end
