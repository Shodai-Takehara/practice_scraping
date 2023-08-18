require 'csv'
require 'write_xlsx'

class CsvToExcelConverter
  def self.convert(file_path)
    csv_data = CSV.read(file_path, headers: true, encoding: 'Shift_JIS')
    workbook = WriteXLSX.new("#{File.basename(file_path, '.csv')}.xlsx")
    worksheet = workbook.add_worksheet

    format_hyperlink = workbook.add_format(underline: 1, color: 'blue')
    format_image = workbook.add_format

    csv_data.headers.each_with_index do |header, cell_idx|
      worksheet.write(0, cell_idx, header)
    end

    csv_data.each_with_index do |row, row_idx|
      row.fields.each_with_index do |cell, cell_idx|
        if cell_idx == 5 # Assuming URL column is at index 5
          worksheet.write_url(row_idx + 1, cell_idx, cell, format_hyperlink)
        elsif cell_idx == 6 # Assuming Image Path column is at index 6
          worksheet.insert_image(row_idx + 1, cell_idx, cell) if File.exist?(cell)
        else
          worksheet.write(row_idx + 1, cell_idx, cell)
        end
      end
    end

    workbook.close
  end
end

if ARGV.length != 1
  puts "Usage: ruby #{__FILE__} <csv_file_path>"
  exit
end

CsvToExcelConverter.convert(ARGV[0])

# require 'rubyXL'
# require 'rubyXL/convenience_methods'
# require 'rubyXL/convenience_methods/cell'
# require 'csv'
# require 'open-uri'

# class CsvToExcelConverter
#   def initialize(csv_file_name)
#     @csv_file_name = csv_file_name
#   end

#   def convert
#     workbook = RubyXL::Workbook.new
#     worksheet = workbook[0]

#     csv_rows = CSV.read(@csv_file_name, headers: true, encoding: 'Shift_JIS:UTF-8')

#     csv_rows.headers.each_with_index do |header, idx|
#       worksheet.add_cell(0, idx, header)
#     end

#     csv_rows.each_with_index do |csv_row, index|
#       csv_row.fields.each_with_index do |cell, cell_idx|
#         if csv_row.headers[cell_idx] == "URL"
#           worksheet.add_cell(index + 1, cell_idx, cell)
#         # 画像のパスから画像を挿入
#         elsif csv_row.headers[cell_idx] == "画像パス" && !cell.nil?
#           worksheet.add_cell(index + 1, cell_idx, cell)
#           image = workbook.add_image(image_src: cell)
#           width = 100 # 画像の幅をピクセル単位で指定
#           height = 100 # 画像の高さをピクセル単位で指定
#           worksheet.add_image(image, noselect: true, start_row: index + 1, start_col: cell_idx, end_row: index + 2, end_col: cell_idx + 1, width: width, height: height)
#         else
#           worksheet.add_cell(index + 1, cell_idx, cell)
#         end
#       end
#     end

#     workbook.write(@csv_file_name.gsub('.csv', '.xlsx'))
#   end
# end

# if ARGV.length != 1
#   puts "Usage: ruby csv_to_excel_converter.rb <csv_file_name>"
#   exit
# end

# csv_file_name = ARGV[0]
# converter = CsvToExcelConverter.new(csv_file_name)
# converter.convert
# puts "Excel file has been created successfully!"
