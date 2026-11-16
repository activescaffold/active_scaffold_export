# frozen_string_literal: true

require 'test_helper'
require 'active_support/concern'

require_relative '../../lib/active_scaffold_export/column'

class ExportColumnTest < Minitest::Test
  class Column
    include ActiveScaffoldExport::Column
  end

  def test_export_options_can_be_assigned_to_columns
    column = Column.new
    column.export_options = {xlsx: {width: 20}}

    assert_equal({xlsx: {width: 20}}, column.export_options)
  end
end
